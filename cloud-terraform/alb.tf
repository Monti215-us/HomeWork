#Application Load Balancer балансирует трафик приложений между хостами. 

#Для его работы потребуются: 
#Target group - группа объединённых эндпоинтов. список хостов, на который должен попасть трафик. 
#Backend Group - Задаёт путь отправки, способ отправки и проверку доступности. 
#HTTP route - определяет, как маршрутизировать HTTP-запрос
#Создание будет написано от ВМ до ALB. 
#При просмотре снизу вверх будет виден путь, который проходит запрос из интернета до ВМ. 

#Создаём target group. Группу целевых хостов.
#как формируется "yandex_compute_instance.web_b.0.ip_address"? 
#yandex_compute_instance - это тип ресурса. Здесь это ВМ. 
#web_b - имя terraform ресурса - ВМ. 
#resource "yandex_compute_instance" "web_a" {
# .0.ip_address формируется и читается автоматически. 
# .[0] - означает первый элемент network_interface. ip_address - внутренний ip

resource "yandex_alb_target_group" "web-site" { #имя ресурса и способ формирования .id для TF
  name = "web-site-target-group" #Имена для человека в YC

#Нужно указать хосты, на которые в конечном счете будут падать запросы. 
  target {
    subnet_id  = yandex_vpc_subnet.private_a.id 
    ip_address = yandex_compute_instance.web_a.[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_b.id
    ip_address = yandex_compute_instance.web_b.[0].ip_address
  }
}




#Создаём backend-group
# target_group_ids — список Target Group, с которыми работает backend.
# ID берём из созданного выше ресурса.

resource "yandex_alb_backend_group" "alb-bg" {
  name = "backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1 
    port             = 80
    target_group_ids = [
      yandex_alb_target_group.web-site.id
      ]

    load_balancing_config {
      panic_threshold = 0
    }
# path = "/" — ALB отправляет HTTP-запрос на корень сайта для проверки работоспособности
    healthcheck {
      timeout  = "5s"
      interval = "5s"
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"
      }
    }
    http2 = "true"
  }
}

# Создаём HTTP Router.
# HTTP Router получает HTTP-запрос от Listener и определяет какой Virtual Host и Route должны его обработать.
# labels — произвольные метки ресурса. Они не участвуют непосредственно в маршрутизации.
resource "yandex_alb_http_router" "alb-router" {
  name = "alb-router"
  labels {
    tf-label    = "tf-label-value"
    empty-label = "s"
  }
}

# Создаём Virtual Host.
# Virtual Host является частью HTTP Router и содержит правила обработки HTTP-запросов.
# Ссылается на роутер, а не роутер на него. 

resource "yandex_alb_virtual_host" "web" {
  name           = "web-host"
  http_router_id = yandex_alb_http_router.alb-router.id

  route {
    name = "web-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.alb-bg.id
        # Указываем Backend Group, куда должен быть отправлен HTTP-трафик.
        # ID берём из созданного выше Backend Group.
      }
    }
  }
}

# Создаём сам Application Load Balancer.
# ALB принимает входящий трафик и передаёт его на backend-серверы
# согласно настройкам HTTP Router.

resource "yandex_alb_load_balancer" "web" {
  name       = "web-alb"
  network_id = yandex_vpc_network.network.id # в какой сети разместить. 

  allocation_policy { #зоны доступности и подсети,
    location { 
      zone_id   = "ru-central1-a" #зона доступности
      subnet_id = yandex_vpc_subnet.private_a.id #в какой подсети размещается
    }

    location { 
      zone_id   = "ru-central1-b" #зона доступности
      subnet_id = yandex_vpc_subnet.private_b.id #в какой подсети размещается
    }
  }

  listener {  #ВАЖНЫЙ! Listener определяет, на каком адресе и порту ALB принимает входящие подключения.
  name = "http"

  endpoint {
    address {
      external_ipv4_address {} #Определяет адрес, на котором принимается трафик для дальнейшей балансировки. 
                               #Если оставить так - то адрес будет выдан автоматически YC после создания. 
    }
    ports = [80] #порт, на котором ALB принимает трафик.  
  }

    # Передаём HTTP-запросы listener в созданный HTTP Router.
    # HTTP Router уже определяет какой Route использовать и в какой Backend Group отправить запрос.

  http { 
    handler {
      http_router_id = yandex_alb_http_router.alb-router.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.alb_sg.id]
  }
}