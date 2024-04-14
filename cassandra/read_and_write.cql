
-- HALL OF FAME

-- READ
CONSISTENCY ONE;

SELECT dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado> AND dungeon_id = <dungeon_id>
LIMIT 5;

-- WRITE

-- Se comprueba si el usuario estaba ya en el top 5
-- y si ha hecho un tiempo mejor.

CONSISTENCY ALL;

SELECT time_minutes AS lowest_time
FROM user_statistics
WHERE dungeon_id = <dungeon_id> AND email = <email_del_usuario> 
LIMIT 1;

-- En caso de que la anterior consulta devuelva un resultado
-- y el tiempo sea menor, se elimina el registro anterior:

CONSISTENCY ALL;

DELETE FROM hall_of_fame
WHERE country = <pais> 
    AND dungeon_id = <dungeon_id> 
    AND email = <email_del_usuario> 
    AND lowest_time = <tiempo_anterior>;

-- Una vez eliminado el registro anterior, se inserta el nuevo
-- registro con el nuevo tiempo:
CONSISTENCY ALL;

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
    now()
);