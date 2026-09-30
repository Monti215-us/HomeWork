#Создаем облачную сеть VPC. Она является вершиной в иерархии сетей. В неё помещаются все ресурсы. 
resource "yandex_vpc_network" "network" {    
  name = "Network"
}
#выше yandex_vpc_network - это ТИП создаваемого ресурса. network - terraform имя ресурса. 
#terraform выдаст id этому ресурсу автоматически по шаблону: "тип_ресурса.tf_имя.id"
#в данном случае "yandex_vpc_network.network.id" и на это имя нужно будет ссылаться дальше. 
# name = "Network" - это имя внутри YandexCloud. 

#Создаём NAT для доступа в интернет. Для него требуется маршрут. Сам по себе не даёт ВМ выхода в интернет.
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

#Создаём маршрут для выхода в интернет через NAT. На него нужно будет ссылать сети, которым нужен интернет.
resource "yandex_vpc_route_table" "rt" {
  name       = "inet"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"  #Для всего трафика
    gateway_id         = yandex_vpc_gateway.nat_gateway.id  #Через данный gateway
  }
}

#Создаем приватную подсеть "a". rt - сокращение от route_table
resource "yandex_vpc_subnet" "private_a" {
  name           = "private_a"
  zone           = "ru-central1-a"  #Зона доступности
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.1.0/24"] # "а" и "b" - разные подсети
  route_table_id = yandex_vpc_route_table.rt.id
  # Подключаем route table с NAT Gateway.
  # Благодаря этому ВМ смогут выходить в Интернет без назначения публичного IP-адреса.
}

#создаем приватную подсеть "b". Нужна для web_b в качестве отказоустойчивости. 
resource "yandex_vpc_subnet" "private_b" {
  name           = "private_b"
  zone           = "ru-central1-b"   #Зона доступности
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.2.0/24"] # "а" и "b" - разные подсети
  route_table_id = yandex_vpc_route_table.rt.id
  # Подключаем route table с NAT Gateway.
  # Благодаря этому ВМ смогут выходить в Интернет без назначения публичного IP-адреса.
}

#создаем публичную подсеть. 
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Дальше идёт пачка security_group. Это настройки fierwall
# Настройка фаервола для Bastion
resource "yandex_vpc_security_group" "bastion_sg" { 
  name       = "bastion_sg" #yandex имя
  network_id = yandex_vpc_network.network.id 
  ingress { #разрешение на входящий трафик. 
    description    = "Разрешить весь входящий TCP трафик на 22 порт/ssh" #описание
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"] #диапазон разрешения на входящий трафик
    port           = 22 
  }

  egress {
    description    = "Разрешить всё исходящее"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0 #От порта 0 
    to_port        = 65535 # до порта 65535
  }

}

#Создание правил для ВМ, на которых работает сайт

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web_sg"
  network_id = yandex_vpc_network.network.id #Сеть, в котором будет работать правило

  ingress { # разрешение на входящий SSH трафик от бастиона.
    description       = "SSH для Bastion" #описание
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress { # разрешение на входящий трафик.
    description       = "Zabbix Agent" #Нужен для пассивных опросов от Zabbix-server
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }

  ingress { # разрешение на входящий трафик. 
    description    = "HTTP для ALB" 
    protocol       = "TCP"
    port           = 80
    security_group_id = yandex_vpc_security_group.alb_sg.id
  #ВАЖНО! здесь НЕ используется 0.0.0.0/0 Web VM не должна принимать HTTP напрямую из Интернета.
  }

  egress {
    description    = "Весь исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

#Создаём правил для Elasticsearch

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name       = "elasticsearch_sg"
  network_id = yandex_vpc_network.network.id

  ingress {#Разрешить только бастиону подключение по SSH. 
    description       = "SSH from Bastion" 
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress { #принятие информации от filebeat к elasticsearch от машин, принадлежащих web_sg 
    description       = "Filebeat для elasticsearch" 
    protocol          = "TCP"
    port              = 9200
    security_group_id = yandex_vpc_security_group.web_sg.id
  }

  ingress { #принятие информации от filebeat к elasticsearch от машин, принадлежащих kibana_sg 
    description       = "Elasticsearch from Kibana"
    protocol          = "TCP"
    port              = 9200
    security_group_id = yandex_vpc_security_group.kibana_sg.id
  }

  ingress { #принятие пассивных запросов от zabbix-server, принадлежащих группе zabbix_sg
    description       = "Zabbix Agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }

  egress { # Разрешаем Elasticsearch устанавливать исходящие соединения.
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создаём Security Group для Kibana.

resource "yandex_vpc_security_group" "kibana_sg" {
  name       = "kibana_sg"
  network_id = yandex_vpc_network.network.id

  ingress { #веб-интерфейс пользователя. 
    description    = "Kibana"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # SSH только от Bastion
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress { # Zabbix Server опрашивает Zabbix Agent
    description       = "Zabbix Agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

#создание правил для zabbix_server

resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix_sg"
  network_id = yandex_vpc_network.network.id

  ingress { #делаем доступным WEB_UI из интернета любому адресу, что не является нормальной практикой. 
    description    = "Zabbix Web UI"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { #Сам Zabbix-server принимает активные данные от других ВМ на этом порту. 
  #Данный порт отдельно не открыт на других ВМ, т.к. им доступны все исходящие порты. 
    description    = "Zabbix Server"
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["10.0.0.0/16"] #Вся наша подсеть  
  }

  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security Group для Application Load Balancer.
# ALB принимает пользовательский HTTP-трафик из Интернета и передаёт его на Web VM.
resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-sg"
  network_id = yandex_vpc_network.network.id

  #Разрешаем пользователям Интернета обращаться к ALB по HTTP.

  ingress {
    description      = "HTTP from Internet"
    protocol         = "TCP"
    port             = 80
    v4_cidr_blocks   = ["0.0.0.0/0"]
  }

  #Разрешаем ALB health checks. Этот порт используется механизмом health check Yandex ALB по умолчанию.
  ingress {
    description       = "ALB health checks"
    protocol          = "TCP"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"
  }

  #ALB должен иметь возможность отправлять трафик к backend ВМ во все подсети.
  egress {
    description    = "Traffic to backends"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }
}

