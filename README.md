# Домашнее задание к занятию "`«Disaster recovery и Keepalived»`" - `Ярцев Максим`

### Инструкция по выполнению домашнего задания

   3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
      - впишите вверху название занятия и вашу фамилию и имя
      - в каждом задании добавьте решение в требуемом виде (текст/код/скриншоты/ссылка)
      - для корректного добавления скриншотов воспользуйтесь [инструкцией "Как вставить скриншот в шаблон с решением](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md)
      - при оформлении используйте возможности языка разметки md (коротко об этом можно посмотреть в [инструкции  по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md))
   4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`);
   5. Для проверки домашнего задания преподавателем в личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
   6. Любые вопросы по выполнению заданий спрашивайте в чате учебной группы и/или в разделе “Вопросы по заданию” в личном кабинете.

1. [Руководство по оформлению Markdown файлов](https://gist.github.com/Jekins/2bf2d0638163f1294637#Code)

---

### Задание 1
- Дана [схема](1/hsrp_advanced.pkt) для Cisco Packet Tracer, рассматриваемая в лекции.
- На данной схеме уже настроено отслеживание интерфейсов маршрутизаторов Gi0/1 (для нулевой группы)
- Необходимо аналогично настроить отслеживание состояния интерфейсов Gi0/0 (для первой группы).
- Для проверки корректности настройки, разорвите один из кабелей между одним из маршрутизаторов и Switch0 и запустите ping между PC0 и Server0.
- Отправьте получившуюся схему в формате pkt и скриншот, где виден процесс настройки маршрутизатора.

### Ответ 1


Файл .ptk внутри репозитория. 
![Для 1 задания](https://github.com/Monti215-us/HomeWork/blob/Disaster-recovery-%D0%B8-Keepalived/img/1.png?raw=true)
---

### Задание 2
- Запустите две виртуальные машины Linux, установите и настройте сервис Keepalived как в лекции, используя пример конфигурационного [файла](1/keepalived-simple.conf).
- Настройте любой веб-сервер (например, nginx или simple python server) на двух виртуальных машинах
- Напишите Bash-скрипт, который будет проверять доступность порта данного веб-сервера и существование файла index.html в root-директории данного веб-сервера.
- Настройте Keepalived так, чтобы он запускал данный скрипт каждые 3 секунды и переносил виртуальный IP на другой сервер, если bash-скрипт завершался с кодом, отличным от нуля (то есть порт веб-сервера был недоступен или отсутствовал index.html). Используйте для этого секцию vrrp_script
- Отправьте получившейся bash-скрипт и конфигурационный файл keepalived, а также скриншот с демонстрацией переезда плавающего ip на другой сервер в случае недоступности порта или файла index.html

### Ответ 1
Получившийся bash-скрипт: 
```
#!/bin/bash

WEB="/var/www/html"
INDEX_FILE="${WEB}/index.html"

# Проверка 80 порта
ss -lnt | grep -q ':80 '

if [ $? -ne 0 ]; then
    exit 1
fi

# Проверка index.html
if [ ! -f "$INDEX_FILE" ]; then
    exit 1
fi

exit 0
```

Конфигурация мастер сервера: 

```
global_defs {
router_id WEB01
}

vrrp_script chk_web {
script "/usr/local/bin/check_web.sh"
interval 3
}

vrrp_instance VI_1 {
state MASTER
interface ens33

virtual_router_id 51

priority 105

authentication {
    auth_type PASS
    auth_pass 1234
}

virtual_ipaddress {
    192.168.11.250
}

track_script {
    chk_web
}

}
```
---
Конфигурация бэкап сервера: 

```
global_defs {
router_id WEB02
}

vrrp_script chk_web {
script "/usr/local/bin/check_web.sh"
interval 3
weight -60
}

vrrp_instance VI_1 {
state BACKUP
interface ens33

virtual_router_id 51

priority 100

authentication {
    auth_type PASS
    auth_pass 1234
}

virtual_ipaddress {
    192.168.11.250
}

track_script {
    chk_web
}

}
```

### Демонстрация работы 2 задания

- На данном скриншоте справа - мастер сервер. Слева - бэкап. На обоих запущен сервис nginx. Рабочий адрес 192.168.11.250 имеет только мастер сервер. 

![Для 2 задания](https://github.com/Monti215-us/HomeWork/blob/Disaster-recovery-%D0%B8-Keepalived/img/2.1.png?raw=true)

- На втором скриншоте сервис nginx отключен на правом сервере и адрес 192.168.11.250 перешёл на резервный сервер. 

![Для 2 задания](https://github.com/Monti215-us/HomeWork/blob/Disaster-recovery-%D0%B8-Keepalived/img/2.2.png?raw=true)
---