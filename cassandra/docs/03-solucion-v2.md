<div align="center">

--- 

# Base de Datos II
## Práctica de Cassandra
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

# Tarea 1
Por el diseño de la arquitectura de Cassandra, es necesario que todos los datos que necesitemos para cada consulta se encuentren almecenados en una única tabla. Puesto que se realiza un total de tres consultas, este es el número de tablas que se han creado. A continuación se argumentan las decisiones de diseño de cada una de las tablas que componen la base de datos.

## Hall of Fame
Se pide el “hall of fame” de cada país, es decir, para un país concreto se muestran para cada mazmorra del juego el TOP 5 de jugadores más rápidos de ese país, incluyendo sus tiempos. En concreto, el formato de salida de los datos requirido es el siguiente:

```python
[
    {
        "dungeon_id": int,
        "dungeon_name": str,
        "top_5": [
            {
                "email": str,
                "user_name": str,
                "time_minutes": float,
                "date": str,
            },
            ...
        ]
    },
    ...
]
```

En SQL, el proceso requiriría la realización de múltiples `JOIN` y agregaciones mediante `GROUP BY`:

```SQL
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
            ORDER BY MIN(time), w.email
        ) AS indx
    FROM WebUser w
        JOIN CompletedDungeons AS cd 
            ON cd.email = w.email
        JOIN Dungeon AS d 
            ON cd.idD = d.idD
    GROUP BY w.email, d.idD, country, date, name, w.userName
    ORDER BY country, d.idD, lowest_time, w.email
) AS t
WHERE indx <= 5 
    AND country = 'es_ES'  -- O cualquier otro país
```

Extraer estos datos en Cassandra requiere la creación de una tabla diseñada ad-hoc para este fin. 

### Diseño de la tabla
La tabla que utilizaremos es la siguiente:

```sql
CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id INT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    lowest_time TINYINT,
    date TIMESTAMP,
    PRIMARY KEY ((country, dungeon_id), lowest_time, email)
    WITH CLUSTERING ORDER BY (lowest_time ASC);
);
```
La solución propuesta permite obtener el listado de jugadores dado un país, con la posibilidad de modificar el ranking deseado de usuarios:

```sql
CONSISTENCY TWO;

SELECT *
FROM hall_of_fame
WHERE country = <pais_deseado>
PER PARTITION LIMIT 5;
```

Designamos `TINYINT` para el tiempo, porque estimamos que se tardará menos de 127 min en completar en una mazmorra, ya que, tras un estudio de los datos, ninguno de los jugadores a nivel global ha tardado más de 49 minutos. Además, estamos considerando tiempos mínimos que tenderán a ser muy bajos. Por otra parte, es posible que en un futuro se amplien a más de las 19 mazmorras actuales, superando las 127, por lo que usaremos `INT`. 

Dado que es necesario para poder acceder a los datos correctamente (usaremos `PER PARTITION LIMIT 5`) establecemos como clave de partición `country` y `dungeon_id`. Por otro lado, utilizaremos `lowest_time` y `email` para que los datos de los nuevos jugadores entren ordenados a la base de datos.

La solución propuesta permite obtener el listado de jugadores dado un país, con la posibilidad de modificar el ranking deseado de usuarios sin ningún problema de rendimiento.

```sql
CONSISTENCY TWO;

SELECT *
FROM hall_of_fame
WHERE country = <pais_deseado>
PER PARTITION LIMIT 5;
```

> [!NOTE]
> Para las operaciones de lectura, modificaremos la consistencia a una más adecuada. En este caso, nos limitaremos a tener mínimo la respuesta de dos nodos, para garantizar que los datos son relativamente fieles a la realidad, pero sin sacrificar rendimiento.

- **Es necesario incluir en la clave de partición la columna `country`** puesto que la consulta se realizará mediante el código de país. De esta forma, se consigue que todos los datos relacionados con un país específico estén localizados en el mismo nodo o un conjunto limitado de nodos en el clúster de Cassandra. Esto optimiza el rendimiento de la consulta al **reducir la latencia** y el tráfico de red necesario para recopilar los datos de diferentes nodos. Además, se facilita la **distribución equilibrada de los datos** a través del clúster, siempre que los datos estén razonablemente balanceados entre los distintos países.

- **La tabla debe contener de antemano el tiempo mínimo por mazmorra de cada usuario.** 
Esto significa que la tabla debe ser diseñada para almacenar y actualizar los récords de los tiempos más bajos de cada jugador para cada mazmorra y país. Al hacerlo, se evitan los cálculos en tiempo real de los tiempos mínimos durante las consultas, lo cual es crítico en Cassandra dado que no se manejan operaciones de agregación complejas eficientemente como lo hace SQL con `GROUP BY`. En concreto, para poder realizar agrupaciones de este tipo es necesario que estas se realicen sobre la clave primaria y siguiendo su orden. En nuestro caso esto implicaría añadir  

### Diseño *Single-Query*
Esta tabla está diseñada para devolver, con una sola consulta, el ranking del país. Para ello se crean cinco grupos de columnas, las cuales representan el top cinco de cada mazmorra. Cada grupo incluiría columnas como `email_1`, `user_name_1`, `time_minutes_1`, `date_1` para el jugador con el tiempo más rápido, seguido por `email_2`, `user_name_2`, etc., hasta `email_5`, `user_name_5`... para el quinto tiempo más rápido. 

### Diseño *Multiple-Query*
Esta tabla utiliza como clave de partición tanto el país como el identificador de la mazmorra y contiene todos los tiempos mínimos de cada usuario ordenados, de manera que para obtener el top cinco, basta con añadir un `LIMIT 5` a la consulta. 

requiere que además de espec
