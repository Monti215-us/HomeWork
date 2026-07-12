# Домашнее задание к занятию "«ELK»" - `Ярцев Максим`

### Задание 1. Elasticsearch 

Установите и запустите Elasticsearch, после чего поменяйте параметр cluster_name на случайный. 

*Приведите скриншот команды 'curl -X GET 'localhost:9200/_cluster/health?pretty', сделанной на сервере с установленным Elasticsearch. Где будет виден нестандартный cluster_name*.

Ответ: 
![1](https://github.com/Monti215-us/HomeWork/blob/ELK/img/1.png?raw=true)
---

### Задание 2. Kibana

Установите и запустите Kibana.

*Приведите скриншот интерфейса Kibana на странице http://<ip вашего сервера>:5601/app/dev_tools#/console, где будет выполнен запрос GET /_cluster/health?pretty*.

Ответ: 
![2](https://github.com/Monti215-us/HomeWork/blob/ELK/img/2.png?raw=true)
---

### Задание 3. Logstash

Установите и запустите Logstash и Nginx. С помощью Logstash отправьте access-лог Nginx в Elasticsearch. 

*Приведите скриншот интерфейса Kibana, на котором видны логи Nginx.*

Ответ: 
![3](https://github.com/Monti215-us/HomeWork/blob/ELK/img/3.png?raw=true)
---

### Задание 4. Filebeat. 

Установите и запустите Filebeat. Переключите поставку логов Nginx с Logstash на Filebeat. 

*Приведите скриншот интерфейса Kibana, на котором видны логи Nginx, которые были отправлены через Filebeat.*

Ответ: 
![4](https://github.com/Monti215-us/HomeWork/blob/ELK/img/4.png?raw=true)
