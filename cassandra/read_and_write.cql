
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
-- Paso 1: Usar la query anterior para comprobar si el tiempo 
-- mejora el peor de los 5 tiempos.
-- Paso 2: Comprobar si el tiempo del usuario es el más bajo suyo.
CONSISTENCY QUORUM;

SELECT time_minute AS lowest_time
FROM player_statistics
WHERE email = <email_usuario> AND dungeon_id = <dungeon_id>
LIMIT 1;

-- Nota: también podríamos utilizar la tabla player_statistics.

-- Si es necesario actualizar el Hall of Fame continuamos.

-- Paso 3 (si el usuario ya estaba en el Hall of Fame):
CONSISTENCY ALL;

DELETE FROM hall_of_fame
WHERE country = <pais> 
    AND dungeon_id = <dungeon_id> 
    AND email = <email_del_usuario> 
    AND lowest_time = <tiempo_anterior>;

-- Paso 4:
CONSISTENCY ALL;

INSERT INTO hall_of_fame (
    country,
    dungeon_id,
    dungeon_name,
    email, username,
    lowest_time,
    date,
)
VALUES (
    <pais>,
    <dungeon_id>,
    <nombre_dungeon>,
    <email_usuario>,
    <nombre_usuario>,
    <nuevo_tiempo>,
    now(),
);

-- PLAYER STATISTICS
---------------------------------

-- READ
CONSISTENCY QUORUM;

SELECT time_minute, date
FROM player_statistics
WHERE email = <email_usuario> AND dungeon_id = <dungeon_id>;

-- WRITE
CONSISTENCY QUORUM;

INSERT INTO player_statistics (dungeon_id, email, time_minute, date)
VALUES (<dungeon_id>, <email_usuario>, <tiempo>, now());


-- HORDE LEADERBOARD
---------------------------------

-- READ
CONSISTENCY ONE;

SELECT username, email, n_kills
FROM hordas
WHERE country = <pais> AND event_id = <id_evento>
GROUP BY email
ORDER BY n_kills DESC
LIMIT <N>;

-- WRITE
CONSISTENCY ONE;

INSERT INTO kills_hordas (country, event_id, username, kills_counter)
VALUES (<pais>, <id_evento>, <nombre_usuario>, <número_de_muertes>)
USING TTL 86400;

UPDATE hordas
SET n_kills = n_kills + 1
WHERE country = <pais> 
    AND event_id = <id_evento> 
    AND email = <email_usuario>;
