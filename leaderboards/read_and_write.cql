
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
    time_in_minutes,
    date
)
VALUES (
    'de_DE',
    0,
    'Burghap, Prison of the Jealous Hippies',
    'thea58@example.net',
    'naseraziz',
    1,
    toTimestamp(now())
);

-- Para saber si debemos actualizar el Hall of Fame, se comprueba si 
-- el tiempo mejora el peor de los 5 tiempos.
SELECT dungeon_id, dungeon_name, email, username, time_in_minutes, date
FROM hall_of_fame
WHERE country = 'de_DE' and dungeon_id = 0;  
-- (valores puestos a modo de ejemplo)

-- PLAYER STATISTICS
---------------------------------

-- READ
CONSISTENCY ONE;

SELECT time_minute, date
FROM player_statistics
WHERE email = 'aaubry@example.net' AND dungeon_id = 0;

-- WRITE
CONSISTENCY LOCAL_QUORUM;

INSERT INTO player_statistics (dungeon_id, email, time_minute, date)
VALUES (0, 'aaubry@example.net', 22, toTimestamp(now()));


-- HORDE LEADERBOARD
---------------------------------

-- READ
CONSISTENCY ONE;

SELECT username, email, n_kills
FROM hordas
WHERE country = 'fr_FR' AND event_id = 16;

-- WRITE
CONSISTENCY ONE;

UPDATE hordas
SET n_kills = n_kills + 1
WHERE country = 'fr_FR' AND event_id = 16 AND email = 'aaubry@example.net' AND username = 'catherine30';

-- Nota:
-- Todos los valores han sido elegidos a modo de ejemplo para facilitar la
-- comprobación de la funcionalidad de las consultas.
