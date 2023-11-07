-- Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT aircraft_code,
       fare_conditions,
       count(s.seat_no)
FROM aircrafts a
         JOIN seats s USING (aircraft_code)
GROUP BY aircraft_code, s.fare_conditions;

-- Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT model,
       count(s.seat_no) AS number_seats
FROM aircrafts
         JOIN seats s USING (aircraft_code)
GROUP BY model
ORDER BY number_seats DESC
LIMIT 3;

-- Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

SELECT aircraft_code,
       model,
       seat_no
FROM aircrafts
         JOIN seats USING (aircraft_code)
WHERE model = 'Аэробус A321-200'
  AND fare_conditions != 'Economy'
ORDER BY seat_no;

-- Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)

SELECT airport_code,
       airport_name,
       city
FROM airports
WHERE city IN (SELECT city
               FROM airports
               GROUP BY city
               HAVING count(*) > 1);

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

SELECT f.flight_id,
       de.city AS departure,
       ar.city AS arrival,
       f.status,
       f.scheduled_departure
FROM flights f
         JOIN airports de on f.departure_airport = de.airport_code
         JOIN airports ar on f.arrival_airport = ar.airport_code
WHERE de.city = 'Екатеринбург'
  AND ar.city = 'Москва'
  AND (f.status = 'On Time'
    OR f.status = 'Delayed')
  AND f.scheduled_departure > bookings.now()
ORDER BY scheduled_departure
limit 1;


-- Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)

WITH sorted_by_amount AS (SELECT min(amount) AS min,
                                 max(amount) AS max
                          FROM ticket_flights)
    (SELECT ticket_flights.*
     FROM ticket_flights
              JOIN sorted_by_amount ON ticket_flights.amount = sorted_by_amount.min
     LIMIT 1)
UNION ALL
(SELECT ticket_flights.*
 FROM ticket_flights
          JOIN sorted_by_amount ON ticket_flights.amount = sorted_by_amount.max
 LIMIT 1);


-- Вывести информацию о вылете с наибольшей суммарной стоимостью билетов

SELECT total_sum, flights_v.*
FROM flights_v
         JOIN
     (SELECT sum(amount) AS total_sum, flight_id AS required_id
      FROM ticket_flights
      GROUP BY flight_id
      ORDER BY total_sum DESC
      LIMIT 1) as selection
     ON flights_v.flight_id = selection.required_id;


-- Найти модель самолета, принесшую наибольшую прибыль (наибольшая суммарная стоимость билетов). Вывести код модели, информацию о модели и общую стоимость

WITH max_profitable_aircraft AS (SELECT f.aircraft_code, sum(tf.amount) as total_amount
                                 FROM flights f
                                          JOIN ticket_flights tf USING (flight_id)
                                 GROUP BY f.aircraft_code
                                 ORDER BY total_amount DESC
                                 LIMIT 1)
SELECT m.aircraft_code, a.model, m.total_amount
FROM max_profitable_aircraft m
         JOIN aircrafts a USING (aircraft_code);

-- Найти самый частый аэропорт назначения для каждой модели самолета. Вывести количество вылетов, информацию о модели самолета, аэропорт назначения, город

WITH airport_frequencies AS (SELECT aircraft_code,
                                    arrival_airport,
                                    arrival_city,
                                    COUNT(arrival_airport)                                        AS departure_count,
                                    MAX(COUNT(arrival_airport)) OVER (PARTITION BY aircraft_code) AS max_count
                             FROM flights_v
                             GROUP BY aircraft_code, arrival_airport, arrival_city)
SELECT departure_count, ad.model, arrival_airport, arrival_city
FROM airport_frequencies af
         RIGHT OUTER JOIN aircrafts ad ON af.aircraft_code = ad.aircraft_code
WHERE departure_count = max_count
   OR departure_count IS NULL;

