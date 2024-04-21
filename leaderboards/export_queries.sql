-- Para un país concreto se muestran para cada mazmorra del juego todos 
-- los jugadores, incluyendo sus tiempos
SELECT email, country, idD, lowest_time, date, name, userName
FROM (
    SELECT
        w.email,
        country,
        d.idD,
        MIN(time) AS lowest_time,
        date,
        name, 
        w.userName,
        ROW_NUMBER() OVER (
            PARTITION BY country, d.idD 
            ORDER BY MIN(time), date
        ) AS indx
    FROM WebUser AS w
        JOIN CompletedDungeons AS cd 
            ON cd.email = w.email
        JOIN Dungeon AS d 
            ON cd.idD = d.idD
    GROUP BY w.email, d.idD, country, date, name, w.userName
    ORDER BY country, d.idD, lowest_time, w.email
) AS t
WHERE indx <= 5 
INTO OUTFILE '/var/lib/mysql-files/HallofFame.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';


-- Estadísticas de un jugador, que muestra los tiempos que ha tardado en 
-- completar una mazmorra en particular ordenados de menor a mayor
SELECT email, idD, time AS time_minute, date
FROM CompletedDungeons
ORDER BY email, idD, time_minute ASC
INTO OUTFILE '/var/lib/mysql-files/Statistics.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';


-- Leaderboar hordas
SELECT w.country, Kills.idE, w.userName, w.email, COUNT(*) AS n_kills
FROM Kills
JOIN WebUser AS w
    ON Kills.email = w.email
GROUP BY Kills.idE, w.country, w.userName, w.email
ORDER BY w.country ASC, Kills.idE ASC, n_kills DESC, w.userName ASC
INTO OUTFILE '/var/lib/mysql-files/Hordas.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';
