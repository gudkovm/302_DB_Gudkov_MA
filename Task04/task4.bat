#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Все пары пользователей, поставивших оценку одному и тому же фильму. Дубликаты устранены, пар с самим собой нет. Выводятся имена обоих пользователей и название фильма, ограничение — 100 строк."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT ua.name AS first_user, ub.name AS second_user, mv.title AS movie FROM (SELECT x.movie_id, x.user_id AS a_id, y.user_id AS b_id FROM ratings x JOIN ratings y ON y.movie_id = x.movie_id AND x.user_id < y.user_id GROUP BY x.movie_id, x.user_id, y.user_id) pairs JOIN users ua ON ua.id = pairs.a_id JOIN users ub ON ub.id = pairs.b_id JOIN movies mv ON mv.id = pairs.movie_id ORDER BY mv.title, ua.name, ub.name LIMIT 100;"
echo " "

echo "2. Десять самых свежих оценок (по одной от каждого пользователя): название фильма, имя пользователя, оценка и дата в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH numbered AS (SELECT user_id, movie_id, rating, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC, id DESC) AS pos FROM ratings) SELECT mv.title AS movie, us.name AS user_name, numbered.rating, strftime('%Y-%m-%d', numbered.timestamp, 'unixepoch') AS review_date FROM numbered JOIN users us ON us.id = numbered.user_id JOIN movies mv ON mv.id = numbered.movie_id WHERE numbered.pos = 1 ORDER BY numbered.timestamp DESC, numbered.user_id ASC LIMIT 10;"
echo " "

echo "3. В одном списке фильмы с наибольшей и наименьшей средней оценкой, отсортированные по году выпуска и названию. В колонке \"Рекомендуем\" стоит \"Да\" или \"Нет\" в зависимости от средней оценки."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH stats AS (SELECT movie_id, AVG(rating) AS avg_r FROM ratings GROUP BY movie_id), edges AS (SELECT MAX(avg_r) AS top_r, MIN(avg_r) AS low_r FROM stats) SELECT mv.title AS movie, mv.year, stats.avg_r AS average_rating, CASE WHEN stats.avg_r = edges.top_r THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM stats JOIN movies mv ON mv.id = stats.movie_id, edges WHERE stats.avg_r IN (edges.top_r, edges.low_r) ORDER BY mv.year ASC, mv.title ASC;"
echo " "

echo "4. Количество оценок и средняя оценка, выставленная фильмам пользователями-женщинами с 2010 по 2012 год включительно."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.rating) AS total_ratings, AVG(r.rating) AS mean_rating FROM ratings AS r INNER JOIN users AS u ON u.id = r.user_id WHERE u.gender IN ('female', 'F', 'f') AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2010' AND '2012';"
echo " "

echo "5. Список фильмов со средней оценкой и позицией в рейтинге по этой средней оценке. Сортировка по году и названию, первые 20 строк."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH computed AS (SELECT movie_id AS mid, AVG(rating) AS mean_r FROM ratings GROUP BY movie_id), ordered AS (SELECT mid, mean_r, RANK() OVER (ORDER BY mean_r DESC) AS position FROM computed) SELECT mv.title AS movie, mv.year, ordered.mean_r AS average_rating, ordered.position AS rating_position FROM ordered JOIN movies mv ON mv.id = ordered.mid ORDER BY mv.year ASC, mv.title ASC LIMIT 20;"
echo " "

echo "6. Десять последних зарегистрированных пользователей в формате \"Фамилия Имя|Дата регистрации\"."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH last_users AS (SELECT name AS full_name, register_date AS reg_date FROM users ORDER BY register_date DESC LIMIT 10) SELECT (CASE WHEN instr(full_name, ' ') > 0 THEN substr(full_name, instr(full_name, ' ') + 1) || ' ' || substr(full_name, 1, instr(full_name, ' ') - 1) ELSE full_name END) || '|' || reg_date AS 'Фамилия Имя|Дата регистрации' FROM last_users ORDER BY reg_date DESC;"
echo " "

echo "7. Таблица умножения для чисел от 1 до 10, собранная через рекурсивный CTE в виде одного столбца \"AxB=C\"."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE counter(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM counter WHERE n < 100) SELECT CAST((n - 1) / 10 + 1 AS TEXT) || 'x' || CAST((n - 1) % 10 + 1 AS TEXT) || '=' || CAST((((n - 1) / 10 + 1) * ((n - 1) % 10 + 1)) AS TEXT) AS multiplication_line FROM counter ORDER BY n;"
echo " "

echo "8. Все жанры из таблицы movies, по одному на строку, с помощью рекурсивного CTE."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE exploded(movie_id, remainder, current_genre) AS (SELECT id, genres || '|', NULL FROM movies UNION ALL SELECT movie_id, substr(remainder, instr(remainder, '|') + 1), substr(remainder, 1, instr(remainder, '|') - 1) FROM exploded WHERE remainder <> '') SELECT DISTINCT current_genre AS genre FROM exploded WHERE current_genre IS NOT NULL AND current_genre <> '' ORDER BY current_genre ASC;"
echo " "