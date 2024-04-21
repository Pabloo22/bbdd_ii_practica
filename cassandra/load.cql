-- `cqlsh --request-timeout=10000`

CREATE KEYSPACE Dungeons 
WITH replication = {
    'class': 'SimpleStrategy', 
    'replication_factor': 2
};

USE dungeons;

CONSISTENCY ALL;

CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id SMALLINT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    time_in_minutes SMALLINT,
    date TIMESTAMP,
    -- Dependiendo de la estrategia de escritura, la clave primaria 
    -- podría utilizar también `dungeon_id` como clave de partición.
    PRIMARY KEY (country, dungeon_id, time_in_minutes, email)  
) WITH CLUSTERING ORDER BY (dungeon_id ASC, time_in_minutes ASC);
-- si se usan borrados periódicos se podría ajustar este parámetro:
-- AND gc_grace_seconds = ?;


COPY hall_of_fame (
    email,
    country,
    dungeon_id,
    time_in_minutes,
    date,
    dungeon_name,
    username
)
FROM '/csv/HallofFame.csv' WITH HEADER = false;

CREATE TABLE player_statistics (
    dungeon_id SMALLINT,
    email VARCHAR,
    time_minute SMALLINT,
    date TIMESTAMP,
    PRIMARY KEY (email, dungeon_id, time_minute, date)
) WITH CLUSTERING ORDER BY (dungeon_id ASC, time_minute ASC);

COPY player_statistics (email, dungeon_id, time_minute, date) 
FROM '/csv/Statistics.csv' WITH HEADER = false;

CREATE TABLE hordas(
    country VARCHAR,
    event_id INT,
    username VARCHAR,
    email VARCHAR,
    n_kills COUNTER,
    PRIMARY KEY ((country, event_id), email, username)
);

COPY hordas (country, event_id, username, email, n_kills) 
FROM '/csv/Hordas.csv' WITH HEADER = false;
