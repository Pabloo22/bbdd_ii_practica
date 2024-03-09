-- `cqlsh --request-timeout=10000`

CREATE KEYSPACE Dungeons WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 2};

USE dungeons;

CONSISTENCY ALL;

CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id TINYINT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    lowest_time TINYINT,
    date TIMESTAMP,
    PRIMARY KEY (country, dungeon_id, lowest_time, email)
);

COPY hall_of_fame (email, country, dungeon_id, lowest_time, date, dungeon_name, username) 
FROM '/var/lib/cassandra/HallofFame.csv' WITH HEADER = false;

CREATE TABLE player_statistics (
    country VARCHAR,
    dungeon_id TINYINT,
    email VARCHAR,
    lowest_time TINYINT,
    date TIMESTAMP,
    PRIMARY KEY (country, dungeon_id, lowest_time, email)
);

COPY player_statistics (email, dungeon_id, lowest_time, date) 
FROM '/var/lib/cassandra/stats.csv' WITH HEADER = false;

CREATE TABLE hordas(
    country VARCHAR,
    event_id INT,
    username VARCHAR,
    email VARCHAR,
    n_kills INT,
    PRIMARY KEY ((country, event_id), n_kills, email)
) WITH CLUSTERING ORDER BY (n_kills DESC, email ASC);

COPY hordas (country, event_id, username, email, n_kills) 
FROM '/var/lib/cassandra/hordas.csv' WITH HEADER = false;
