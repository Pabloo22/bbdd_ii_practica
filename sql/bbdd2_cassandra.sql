-- SQL!!

--  para un país concreto se muestran para cada mazmorra del juego todos los jugadores, incluyendo sus tiempos
SELECT email, country, idD, lowest_time, date, name, indx, userName
FROM (
	SELECT w.email, country, d.idD, MIN(time) lowest_time, date, name, w.userName, ROW_NUMBER() OVER (PARTITION BY country, d.idD ORDER BY MIN(time), w.email) AS indx
	FROM WebUser w
	JOIN CompletedDungeons cd ON cd.email = w.email
	JOIN Dungeon d ON cd.idD = d.idD
	GROUP BY w.email, d.idD, country, date, name, w.userName
	ORDER BY country, d.idD, lowest_time, w.email
) AS t
WHERE indx <= 5
INTO OUTFILE '/var/lib/mysql-files/HallofFame.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';


-- estadísticas de un jugador, que muestra los tiempos que ha tardado en completar una mazmorra en particular ordenados de menor a mayor
SELECT email, idD, time, date
FROM CompletedDungeons
ORDER BY email, idD, time ASC
INTO OUTFILE '/var/lib/mysql-files/Statistics.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- CASSANDRA!!
cqlsh --request-timeout=10000
CREATE KEYSPACE Dungeons WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3}
USE dungeons;
CONSISTENCY ALL;

CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id INT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    lowest_time INT,
    date TIMESTAMP,
    PRIMARY KEY (country, dungeon_id, lowest_time, email)
);

COPY hall_of_fame (email, country, dungeon_id, lowest_time, date, dungeon_name, username) FROM '/var/lib/cassandra/HallofFame.csv' WITH HEADER = false;

CREATE TABLE player_statistics (
    email VARCHAR,
    dungeon_id INT,
    lowest_time TINYINT,
    date TIMESTAMP,
    PRIMARY KEY (email, dungeon_id, date)
);

COPY player_statistics (email, dungeon_id, lowest_time, date) FROM '/var/lib/cassandra/Statistics.csv' WITH HEADER = false;


