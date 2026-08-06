# Домашнее задание к занятию "SQL. Часть 2" - `Ярцев Максим`

### Задание 1

Одним запросом получите информацию о магазине, в котором обслуживается более 300 покупателей, и выведите в результат следующую информацию: 
- фамилия и имя сотрудника из этого магазина;
- город нахождения магазина;
- количество пользователей, закреплённых в этом магазине.
### Ответ 1

```
SELECT
    s.last_name,
    s.first_name,
    c.city,
    COUNT(cust.customer_id) AS customers_count
FROM store st
JOIN staff s
    ON st.manager_staff_id = s.staff_id
JOIN address a
    ON st.address_id = a.address_id
JOIN city c
    ON a.city_id = c.city_id
JOIN customer cust
    ON st.store_id = cust.store_id
GROUP BY
    st.store_id,
    s.last_name,
    s.first_name,
    c.city
HAVING COUNT(cust.customer_id) > 300;
```

### Задание 2

Получите количество фильмов, продолжительность которых больше средней продолжительности всех фильмов.

### Ответ 2
```
SELECT COUNT(*) AS films_count
FROM film
WHERE length >
(
    SELECT AVG(length)
    FROM film
);
```
### Задание 3

Получите информацию, за какой месяц была получена наибольшая сумма платежей, и добавьте информацию по количеству аренд за этот месяц.

### Ответ 3
```
SELECT
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    SUM(amount) AS total_amount
FROM payment
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY total_amount DESC
LIMIT 1;
```