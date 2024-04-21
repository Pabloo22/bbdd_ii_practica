
-- HALL OF FAME
---------------------------------

-- READ
-------------
CONSISTENCY ONE;

SELECT dungeon_id, dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = 'de_DE';

-- WRITE
-------------
CONSISTENCY LOCAL_QUORUM;

INSERT INTO hall_of_fame (
    country,
    dungeon_id,
    dungeon_name,
    email, username,
    lowest_time,
    date
)
VALUES (
    <pais>,
    <dungeon_id>,
    <nombre_dungeon>,
    <email_usuario>,
    <nombre_usuario>,
    <nuevo_tiempo>,
    toTimestamp(now())
);

-- Para saber si debemos actualizar el Hall of Fame, se comprueba si 
-- el tiempo mejora el peor de los 5 tiempos.
SELECT dungeon_id, dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = 'de_DE' and dungeon_id = 0;  
-- (valores puestos a modo de ejemplo)

-- PLAYER STATISTICS
---------------------------------

-- READ
CONSISTENCY ONE;

SELECT time_minute, date
FROM player_statistics
WHERE email = <email_usuario> AND dungeon_id = <dungeon_id>;

-- WRITE
CONSISTENCY LOCAL_QUORUM;

INSERT INTO player_statistics (dungeon_id, email, time_minute, date)
VALUES (<dungeon_id>, <email_usuario>, <tiempo>, toTimestamp(now()));


-- HORDE LEADERBOARD
---------------------------------

-- READ
CONSISTENCY ONE;

SELECT username, email, n_kills
FROM hordas
WHERE country = <pais> AND event_id = <id_evento>;

-- WRITE
CONSISTENCY ONE;

INSERT INTO kills_hordas (country, event_id, username, kills_counter)
VALUES (<pais>, <id_evento>, <nombre_usuario>, <número_de_muertes>);
-- USING TTL 86400;

UPDATE hordas
SET n_kills = n_kills + 1
WHERE country = <pais> 
    AND event_id = <id_evento> 
    AND email = <email_usuario>;
