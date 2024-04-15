-- `cqlsh --request-timeout=10000`

CREATE KEYSPACE Dungeons 
WITH replication = {
    'class': 'SimpleStrategy', 
    'replication_factor': 2,
};

USE dungeons;

CONSISTENCY ALL;

CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id SMALLINT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    lowest_time SMALLINT,
    date TIMESTAMP,
    PRIMARY KEY ((country, dungeon_id), lowest_time, email)
    WITH CLUSTERING ORDER BY (lowest_time ASC);
);

COPY hall_of_fame (
    email,
    country,
    dungeon_id,
    lowest_time,
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
    PRIMARY KEY (email, dungeon_id, date, time_minute)
) WITH CLUSTERING ORDER BY (time_minute ASC);

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
