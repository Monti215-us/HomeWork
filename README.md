# Домашнее задание к занятию "`Защита сети`" - `Ярцев Максим`

### Задание 1
Проведите разведку системы и определите, какие сетевые службы запущены на защищаемой системе:

sudo nmap -sA < ip-адрес >

sudo nmap -sT < ip-адрес >

sudo nmap -sS < ip-адрес >

sudo nmap -sV < ip-адрес >

По желанию можете поэкспериментировать с опциями: https://nmap.org/man/ru/man-briefoptions.html.

В качестве ответа пришлите события, которые попали в логи Suricata и Fail2Ban, прокомментируйте результат.

### Ответ 1

В логи Suricata попало следующее: 
```
08/28/2026-14:07:29.851379  [**] [1:2010937:3] ET SCAN Suspicious inbound to mySQL port 3306 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:34738 -> 192.168.11.134:3306
08/28/2026-14:07:29.882495  [**] [1:2010939:3] ET SCAN Suspicious inbound to PostgreSQL port 5432 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:38640 -> 192.168.11.134:5432
08/28/2026-14:07:29.902001  [**] [1:2002910:6] ET SCAN Potential VNC Scan 5800-5820 [**] [Classification: Attempted Information Leak] [Priority: 2] {TCP} 192.168.11.190:58582 -> 192.168.11.134:5810
08/28/2026-14:07:29.921500  [**] [1:2010936:3] ET SCAN Suspicious inbound to Oracle SQL port 1521 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:58218 -> 192.168.11.134:1521
08/28/2026-14:07:29.941494  [**] [1:2010935:3] ET SCAN Suspicious inbound to MSSQL port 1433 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:57660 -> 192.168.11.134:1433
08/28/2026-14:07:33.814573  [**] [1:2010937:3] ET SCAN Suspicious inbound to mySQL port 3306 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:42836 -> 192.168.11.134:3306
08/28/2026-14:07:33.841703  [**] [1:2010935:3] ET SCAN Suspicious inbound to MSSQL port 1433 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:42836 -> 192.168.11.134:1433
08/28/2026-14:07:33.877558  [**] [1:2010936:3] ET SCAN Suspicious inbound to Oracle SQL port 1521 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:42836 -> 192.168.11.134:1521
08/28/2026-14:07:33.888554  [**] [1:2010939:3] ET SCAN Suspicious inbound to PostgreSQL port 5432 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:42836 -> 192.168.11.134:5432
08/28/2026-14:07:36.049641  [**] [1:2010937:3] ET SCAN Suspicious inbound to mySQL port 3306 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:36495 -> 192.168.11.134:3306
08/28/2026-14:07:36.056010  [**] [1:2010936:3] ET SCAN Suspicious inbound to Oracle SQL port 1521 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:36495 -> 192.168.11.134:1521
08/28/2026-14:07:36.060245  [**] [1:2010939:3] ET SCAN Suspicious inbound to PostgreSQL port 5432 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:36495 -> 192.168.11.134:5432
08/28/2026-14:07:36.075222  [**] [1:2010935:3] ET SCAN Suspicious inbound to MSSQL port 1433 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:36495 -> 192.168.11.134:1433
08/28/2026-14:07:36.230972  [**] [1:2010939:3] ET SCAN Suspicious inbound to PostgreSQL port 5432 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:38116 -> 192.168.11.134:5432
08/28/2026-14:07:42.251669  [**] [1:2010939:3] ET SCAN Suspicious inbound to PostgreSQL port 5432 [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 192.168.11.190:44608 -> 192.168.11.134:5432
08/28/2026-14:07:42.260923  [**] [1:2260002:1] SURICATA Applayer Detect protocol only one direction [**] [Classification: Generic Protocol Command Decode] [Priority: 3] {TCP} 192.168.11.190:44620 -> 192.168.11.134:5432
08/28/2026-14:07:42.278448  [**] [1:2100598:14] GPL RPC portmap listing TCP 111 [**] [Classification: Decode of an RPC Query] [Priority: 2] {TCP} 192.168.11.190:553 -> 192.168.11.134:111
08/28/2026-14:07:42.280584  [**] [1:2100598:14] GPL RPC portmap listing TCP 111 [**] [Classification: Decode of an RPC Query] [Priority: 2] {TCP} 192.168.11.190:553 -> 192.168.11.134:111
```
В логи Fail2Ban эти сканирования не попали вовсе, т.к. до авторизации дело не дошло. 

В логах Suricata видно, что он успешно обнаружил часть сканирований nmap, однако, в логи не попали сканы от команды 
```
nmap -sA
```
---

### Задание 2

Проведите атаку на подбор пароля для службы SSH:

hydra -L users.txt -P pass.txt < ip-адрес > ssh

1. Настройка hydra:
создайте два файла: users.txt и pass.txt;
в каждой строчке первого файла должны быть имена пользователей, второго — пароли. В нашем случае это могут быть случайные строки, но ради эксперимента можете добавить имя и пароль существующего пользователя.
Дополнительная информация по hydra: https://kali.tools/?p=1847.

2. Включение защиты SSH для Fail2Ban:
открыть файл /etc/fail2ban/jail.conf,
найти секцию ssh,
установить enabled в true.
Дополнительная информация по Fail2Ban:https://putty.org.ru/articles/fail2ban-ssh.html.

В качестве ответа пришлите события, которые попали в логи Suricata и Fail2Ban, прокомментируйте результат.

### Ответ 2
В логи Suricata попадали события типа: 
```
08/28/2026-14:42:20.854485  [**] [1:2003068:7] ET SCAN Potential SSH Scan OUTBOUND [**] [Classification: Attempted Information Leak] [Priority: 2] {TCP} 192.168.11.190:56454 -> 192.168.11.134:22
```
В логи Fail2Ban попали события попытки входа и сообщения о блокировке ip атакующего: 

```
2026-08-28 14:42:06,446 fail2ban.filter         [58138]: INFO    [sshd] Found 192.168.11.190 - 2026-08-28 14:42:05
2026-08-28 14:42:06,447 fail2ban.actions        [58138]: WARNING [sshd] 192.168.11.190 already banned
```