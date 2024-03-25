--  para un país concreto se muestran para cada mazmorra del juego todos los jugadores, incluyendo sus tiempos
SELECT email, country, idD, lowest_time, date, name, userName
FROM (
	SELECT w.email,
		   country, 
		   d.idD, 
		   MIN(time) lowest_time, 
		   date, 
		   name, 
		   w.userName, 
		   ROW_NUMBER() OVER (PARTITION BY country, d.idD ORDER BY MIN(time), w.email) AS indx
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


-- Leaderboar hordas
SELECT WebUser.country, Kills.idE, WebUser.userName, WebUser.email, COUNT(*) n_kills
FROM Kills
JOIN WebUser ON Kills.email = WebUser.email
GROUP BY Kills.idE, WebUser.country, WebUser.userName, WebUser.email
ORDER BY WebUser.country ASC, Kills.idE ASC, n_kills DESC, WebUser.userName ASC
INTO OUTFILE '/var/lib/mysql-files/Hordas.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';
