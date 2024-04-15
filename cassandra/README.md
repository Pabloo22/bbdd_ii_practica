<div align="center">

--- 

# Base de Datos II
## Práctica de Cassandra
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

# Enunciado

## Introducción
En el videojuego “Jotun’s Lair” de la empresa “Norsewind studios”, existen unos
leaderboards que muestran los tiempos que han tardado los usuarios en completar las
mazmorras. 

Sin embargo, en los últimos años, el juego ha cogido mucha popularidad y el
número de jugadores y países donde se vende el juego creció mucho. El equipo de
operaciones ha notado que la base de datos relacional que usan no cumple con los
objetivos de rendimiento ni de escalabilidad necesarios para dar soporte a los
leaderboards del juego.

<div align="center">
<img src="diagrama_er.png" width=80% height=80% align="center">
</div>
<br>
En concreto, los jugadores pueden examinar tres *leaderboards* que se deben ir actualizando en tiempo real:

### Hall of Fame

El “**hall of fame**” de cada país, es decir, para un país concreto se muestran
para cada mazmorra del juego el TOP 5 de jugadores más rápidos de ese país, incluyendo sus tiempos.

> [!IMPORTANT]
> Un pequeño retardo a la hora de actualizar o mostrar estos leaderboards no tiene impacto en el juego.

### Estadísticas de un jugador

Muestra los tiempos que ha tardado en
completar una mazmorra en particular ordenados de menor a mayor.

> [!IMPORTANT]
> Un pequeño retardo a la hora de actualizar o mostrar estos leaderboards no tiene impacto en el juego.

### Hordas

El equipo de “game design” quiere introducir un leaderboard para las Hordas que muestre los N jugadores que más monstruos han matado hasta el momento durante una Horda en concreto.

Una Horda es un evento especial del juego en la que los jugadores deben resistir en una fortaleza del mapa oleadas de monstruos que tratan de conquistar la fortaleza.

> [!IMPORTANT]
>
> - Una Horda tiene una duración de unos 30-40 minutos.
> - Cualquier retraso a la hora de enviar/recibir la información es crítico.
> - La consistencia en este leaderboard no es tan importante.


## Objetivo

Se desea realizar un prototipo de una base de datos de Cassandra para dar servicio a los tres leaderboards anteriores. El juego hace tres peticiones de lectura al servidor que se resumen en la siguiente tabla:

<div align="center">
<img src="tabla_lecturas.png" height=75% width=75% align="center">
</div>
<br>

La fila "rank" indica el leaderbord que se puebla con la
petición de lectura, la fila "in" indica los parámetros de entrada que recibe la llamada y "out" indica el formato de los datos que devuelve el servidor.

Además, el juego hace dos peticiones de escritura al servidor que se ejecutan cuando
ocurre un evento concreto durante el juego. La siguiente tabla muestra la información de
las peticiones de escritura, la fila “When” indica el evento en el juego que dispara la
petición de escritura y la fila “data” indica los datos que se envían al servidor: 

<div align="center">
<img src="tabla_escrituras.png" height=75% width=75% align="center">
</div>

## Tareas

1. Diseña una base de datos Cassandra para dar servicio a las lecturas y escrituras
anteriores. Argumenta tus decisiones de diseño.

2. Crea las consultas .sql necesarias para exportar los datos de la base de datos
relacional a ficheros .csv. Los ficheros deberán tener un formato acorde al diseño
del punto 1.

3. Prepara un cluster local de 3 nodos todos en el mismo rack y datacenter.
   
4. Haz un fichero .cql que creen tu diseño en Cassandra y cargue los ficheros .csv
creados en el paso 2. Se debe utilizar un factor de replicación de 2 y tener en
cuenta que se las pruebas se ejecutaran en un cluster local.

5. OPCIONAL Si el diseño lo necesita, actualiza la tabla de escrituras para incluir
cualquier modificación que sea necesaria en la información que se le debe
proporcionar al servidor.

6. Haz un fichero .cql que realice las consultas de escritura y lectura necesarias.
Incluye el nivel de consistencia de cada consulta, teniendo en cuenta las
características de los diferentes rankings.

Debido al aumento de la popularidad del juego, la base de usuarios y el número de países donde se vende el juego han aumentado significativamente. El equipo de operaciones ha notado que la base de datos relacional que usan no cumple con los objetivos de rendimiento ni de escalabilidad necesarios para dar soporte a los *leaderboards* del juego.

# Justificación del uso de Cassandra

En esta sección, se realiza una breve explicación de las cualidades de Cassandra. Hemos decidido añadir esta sección puesto que entender el funcionamiento de Cassandra correctamente es esencial para poder completar adecuadamente las tareas anteriormente planteadas. Sin embargo, para realizar esta explicación, es necesario describir primero cuales son las limitaciones de las base de datos relacional en este contexto, ya que la decisión de utilizar Cassandra surge a raíz de tratar de solventar estos desafíos. 

## ¿Por qué una base de datos relacional no es adecuada?

Los motivos por los cuales la antigua base de datos relacional no cumple con los requisitos anteriormente mencionados son varios:

- **Escalabilidad limitada:** este tipo de bases de datos están preparadas para un escalado vertical (ej. comprar un mejor ordenador). Esta estrategia, sin embargo, es mucho más limitada que su alternativa: el escalado horizontal; debido a que, normalmente, es mucho más costoso mejorar el servidor que añadir más nodos a la red. La escalabilidad horizontal de las bases de datos relacionales es complicada debido a que se tienen que conservar las propiedades ACID (Atomicidad, Consistencia, Aislamiento y Durabilidad).

- **Consultas complejas:** realizar las consultas necesarias para crear los *leaderboards* requieren un gran número de *joins* y agregaciones de grandes volúmenes de datos, por lo que pueden resultar en mucha latencia. Por ejemplo, para crear la consulta relacionada con el *Hall* de la Fama, es necesario realizar dos *joins* de tablas muy grandes como son `Dungeon`, `Completes` y `WebUser`.

- **Disponibilidad comprometida:** las bases de datos relacionales se aseguran que los datos son siempre consistentes. No obstante, en un entorno distribuido en el que se da servicio a varios países, esta consistencia perfecta únicamente se puede conseguir sacrificando disponibilidad (teorema CAP). No obstante, si bien se requiere de una consistencia eventual, es mucho más importante garantizar la disponibilidad en todo momento de los datos. Es decir, que siempre que se consulte el ranking este se encuentre disponible.

- **Alto volúmen de escrituras:** este tipo de bases de datos no están diseñadas para un volumen excesivo de escrituras. Esto se debe a que cada escritura implica, a menudo, actualizar los índices asociados. Por otro lado, muchas escrituras concurrentes, los bloqueos encargados de asegurar que los datos son consistentes, pueden hacerse más frecuentes y durar más.

## ¿Por qué Apache Cassandra?
Utilizar una base de datos basada en Apache Cassandra soluciona los problemas mencionados anteriormente. Esto se debe a que Cassandra está diseñada específicamente diseñada para entornos distribuidos y con altas cargas de trabajo.

- **Escalabilidad sencilla:** se utiliza una arquitectura distribuida sin un solo punto de falla, lo que permite añadir más nodos sin tiempo de inactividad y con un balanceo de carga automático. Gracias a este diseño (más detalles en la siguiente sección), las limitaciones de escalabilidad anteriormente mencionadas desaparecen al poder escalar la base de datos horizontalmente de forma sencilla.

- **Consultas sencillas:** se sacrifica la integridad referencial y la flexibilidad de las bases de datos a cambio de un mayor rendimiento. Esto se consigue diseñando la base de datos para soportar un conjunto específico de consultas. Ya no se permiten operaciones como *joins*, toda la información necesaria para la lectura debe estar contenida en una única tabla. Sin embargo, esta es también una limitación: la falta de joins y otras características de bases de datos relacionales puede complicar el diseño del esquema y la implementación de ciertas funcionalidades que en una base de datos relacional serían más directas.

- **Alta disponibilidad:** la consistencia ya no es la prioridad, sino que se prioriza el rendimiento. Esto se consigue distribuyendo réplicas de los datos a través de una red distribuida y la cual no tiene un único punto de fallo (SPoF). Las particiones se distribuyen en función de la clave primaria, la cual a su vez se compone de la clave de partición y la de clustering. La clave de partición es por la cual los datos son repartidos. Cada nodo conoce que claves de este tipo almacena, así como las del resto de nodos de la red. Por otro lado, la clave de clustering nos permite diferenciar unos registros de otros y ordenarlos a raíz de sus valores. Esto supone una ventaja puesto que si realizamos una consulta como "dame todos los usarios de este país", si hemos utilizado como clave de partición el país, podemos obtener este resultado consultando a tan solo unos pocos nodos. Al estar duplicada la información, que uno o varios nodos no contesten no es un problema siempre y cuando haya un número suficiente (lo específicamos nosotros) que lo hagan. De esta forma se evitan altos tiempos de carga a la hora de cargar los rankings, posibilitándose la visualización en tiempo real de ellos durante eventos como las Hordas.

- **Soporte para grandes volúmenes de escrituras:** las escrituras a disco se realizan en batches una vez la cantidad de memoria RAM utilizada ha sobrepasado cierta cantidad. De esta forma, se realiza una carga de los datos más eficiente al poder realizarse concurrentemente. Además, si varias operaciones de escritura se han recibido sobre un mismo registro únicamente este se actualiza con el que tenga el *timestamp* más reciente, reduciendo el número de datos a escribir en disco.

# Solución propuesta

## Tarea 1: Diseño base de datos Cassandra

Por el diseño de la arquitectura de Cassandra, es necesario que todos los datos que necesitemos para cada consulta se encuentren almecenados en una única tabla. Puesto que se realiza un total de tres consultas, este es el número de tablas que se han creado. A continuación se argumentan las decisiones de diseño de cada una de las tablas que componen la base de datos.

En concreto, se ha atendido a las siguientes cuestiones:

1. Con la **elección de la clave de partición** debemos de asegurarnos de que: incluya los campos por los que se realizará la lectura; y, segundo, que los datos se repartan de forma equitativa por todo el clúster. Es decir, la clave de partición debe estar compuesta por campos cuyos valores estén repartidos de manera relativamente uniforme. Por otro lado, particiones muy grandes pueden ser contraproducentes, ya que consumen más memoria y pueden causar latencias durante las lecturas.

2. Debemos **evitar la necesidad de realizar agregaciones** con datos que puedan estar alojados en múltiples nodos. El motivo es que esto aumentaría significativamente la latencia al requerir coordinación entre ellos para consolidar y calcular los resultados finales.

### Hall of Fame

Se pide el “hall of fame” de cada país, es decir, para un país concreto se muestran para cada mazmorra del juego el TOP 5 de jugadores más rápidos de ese país, incluyendo sus tiempos. La tabla que hemos diseñado y que da solución a esta consulta es la siguiente:

```sql
CREATE TABLE hall_of_fame (
    country VARCHAR,
    dungeon_id SMALLINT,
    dungeon_name VARCHAR,
    email VARCHAR,
    username VARCHAR,
    lowest_time SMALLINT,
    date TIMESTAMP,
    PRIMARY KEY ((country, dungeon_id), lowest_time, email)
) WITH CLUSTERING ORDER BY (lowest_time ASC);
```

Con este diseño, todos los datos necesarios para la consulta anterior se pueden obtener mediante la siguiente consulta:

```sql
CONSISTENCY ONE;

SELECT dungeon_id, dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado>
PER PARTITION LIMIT 5;
```

Podemos utilizar un nivel de consistencia de uno, ya que las escrituras se realizan con un nivel de consistencia de `ALL`, lo que garantiza que los datos se replican en todos los nodos y, por tanto, se encuentran disponibles en todo momento.

#### Justificación

La clave de partición se compone de `country` y `dungeon_id`. Esta elección se hace para garantizar que las consultas sean rápidas y no requieran buscar en múltiples particiones. De esta forma, nos aseguramos de que los datos para cada combinación de país y mazmorra estén localizados en el mismo nodo, reduciendo así la necesidad de realizar operaciones entre varios nodos.

Por otro lado, la clave de clustering `lowest_time` se utiliza para ordenar los resultados dentro de cada partición por el tiempo más bajo primero. Esto es crucial ya que permite una recuperación eficiente del top 5 de tiempos más bajos directamente de la base de datos, sin necesidad de procesamiento adicional o de ordenamiento en la aplicación cliente.

De esta forma, podemos utilizar `PER PARTITION LIMIT 5` para asegurarnos de que solo se devuelvan los cinco mejores registros por cada mazmorra dentro de un país. Este límite es manejado eficientemente por Cassandra, que puede aprovechar el ordenamiento físico de los datos dentro de la partición por la clave de clustering para cortar la búsqueda tan pronto como se obtienen los cinco mejores registros.

La adición de `email` a la clave de clustering nos permite poder identificar cada entrada de manera unica. En caso contrario, sería imposible que en el ranking hubiera filas con un mismo `lowest_time`.

Con respecto a los tipos de datos utilizados en cada columna, las variables de tipo texto se han definido como `VARCHAR`, ya que no que se requiera de más espacio en memoria para estas. Por otro lado, pensamos en utilizar `TINYINT` para `lowest_time`. Si bien estimamos que se tardará menos de 127 min en completar en una mazmorra, ya que, tras un estudio de los datos, ninguno de los jugadores a nivel global ha tardado más de 49 minutos. En el futuro es posible que se diseñen mazmorras con una duración muy larga, y, por tanto, creemos que es más conservador utilizar el tipo `SMALLINT`, el cual nos permite almacenar enteros hasta 32767. De la misma forma, es posible que en un futuro se amplie el número de mazzmorras a más de las 19 mazmorras actuales, superando las 127, por lo que usaremos de nuevo `SMALLINT` para la columna `dungeon_id`.

Esto es especialmente importante, puesto que, la aplicación debe evitar la adición de más de una entrada para un mismo usuario. En caso contrario, es posible que un mismo usuario aparezca múltiples veces en un mismo ranking. A continuación, se muestra la lógica que podría seguir la aplicación a la hora de realizar escrituras en esta tabla para solucionar este problema:

#### Lógica de las escrituras

Cada vez que un usuario completa una mazmorra, se comprueba si su tiempo está en el top 5 para la mazmorra y país correspondiente:

```sql
CONSISTENCY ONE;

SELECT dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado> AND dungeon_id = <dungeon_id>
LIMIT 5;
```

Como se ha mencionado anteriormente, podemos utilizar un nivel de consistencia de uno, ya que las escrituras se realizan con un nivel de consistencia de `ALL`. Es necesario remarcar esto, porque es importante que las lecturas que realicemos en este proceso sean consistentes para evitar añadir a un mismo usuario más de una vez en el ranking.

Solamente si el tiempo de completitud es inferior al del top 5 del ranking deberemos seguir con el proceso. 

El siguiente paso es comprobar si el usuario está en la tabla para esa mazmorra. De esta forma podemos recuperar el record de dicho usuario en caso de que tenga alguno. Para consultar cual fue su mejor tiempo en dicha mazmorra, podemos utilizar la siguiente consulta:

```sql
CONSISTENCY QUORUM;

SELECT time_minute AS lowest_time
FROM player_statistics
WHERE email = <email_usuario> AND dungeon_id = <dungeon_id>
LIMIT 1;
```

Para más información sobre la tabla `player_statistics`, ver la siguiente sección. Esta tabla utiliza un nivel de consistencia de `QUORUM` tanto para para las escrituras. Por tanto, utilizar `QUORUM` en esta consulta nos garantiza obtener un valor consistente. 

Si se comprueba que el usuario ha batido su record personal, o que no se encontraba en el ranking, entonces actualizamos o añadimos la entrada correspondiente. Para actualizar el registro es necesario eliminar el antiguo primero:

```sql
CONSISTENCY ALL;

DELETE FROM hall_of_fame
WHERE country = <pais> 
    AND dungeon_id = <dungeon_id> 
    AND email = <email_del_usuario> 
    AND lowest_time = <tiempo_anterior>;
``` 

Una vez eliminado, se añade el nuevo registro al ranking:

```sql
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
```

Aplicando un nivel de consistencia `ALL` nos aseguramos de que no se produzca ninguna pérdida de datos. Además, el tiempo extra que supone utilizar un nivel de consistencia `ALL` y es asumible en este ranking debido a que un pequeño retardo a la hora de actualizarlo no tiene impacto en el juego, y a que el número de escrituras es presumiblemente bajo en este caso.

### Estadísticas de usuario

Esta tabla debe contener los tiempos que cada usuario ha tardado en completar una mazmorra en particular ordenados de menor a mayor. El diseño de tabla que cumpliría dicho propósito es el siguiente:

```sql
CREATE TABLE player_statistics (
    dungeon_id SMALLINT,
    email VARCHAR,
    time_minute SMALLINT,
    date TIMESTAMP,
    PRIMARY KEY (email, dungeon_id, date, time_minute)
) WITH CLUSTERING ORDER BY (time_minute ASC);
```

De esta forma, se pueden obtener los tiempos mediante la siguiente consulta:

```sql
CONSISTENCY QUORUM;

SELECT time_minute, date
FROM player_statistics
WHERE email = <email_usuario> AND dungeon_id = <dungeon_id>;
```

Utilizamos un nivel de consistencia de `QUORUM` tanto para las lecturas como para las escrituras. Hemos utilizado este nivel de consistencia en ambos casos ya que, por un lado, es positivo asegurarnos de que los datos son consistentes y, por otro lado, esperamos un volumen de escrituras y lecturas balanceados en esta tabla. Es asumible el tiempo extra que supone utilizar este nivel de consistencia en este caso, ya que un pequeño retardo a la hora de actualizar las estadísticas de un usuario no tiene impacto en el juego.

#### Justificación

Como clave de partición hemos decidido usar únicamente `email`. Creemos que esto es preferible a usar `email` y `dungeon_id` puesto que esto podría resultar en particiones demasiado pequeñas al ser probable que haya un conjunto de usuarios con pocas partidas. Añadir `dungeon_id` dividiría aún más estas particiones lo que potencialmente nos llevaría a tener particiones demasiado granulares. Además, utilizando únicamente `email`, la consulta sigue siendo igualmente eficiente pese a que también filtremos por mazmorra. Por otro lado, no utilizamos únicamente `dungeon_id` puesto que esto podría resultar en particiones demasiado grandes.

En cuanto a la clave de clustering, es necesario incluir todos los campos. Añadiendo `date` nos aseguramos de que cada registro es único y, por tanto, no se sobreescribirán. Añadir `time_minute` nos permite ordenar los registros por tiempo, lo cual es esencial para poder recuperarlos de manera ordenada de manera más eficiente.

En este caso, las escrituras son mucho más sencillas. Simplemente, cada vez que un usuario completa una mazmorra se ejecuta el siguiente *insert*:

```sql
CONSISTENCY QUORUM;

INSERT INTO player_statistics (dungeon_id, email, time_minute, date)
VALUES (<dungeon_id>, <email_usuario>, <tiempo>, now());
```

Con el nivel de consistencia `ALL` nos aseguramos de que no se produzca ninguna pérdida de datos. Además, el tiempo extra que supone el realizar estas comprobaciones es asumible en este ranking ya que un pequeño retardo a la hora de actualizarlo no tiene impacto en el juego.

Las decisiones de los tipos de datos son las mismas que en *Hall of Fame*.

### Hordas

Este *leaderboard* muestra los N jugadores que más monstruos han matado hasta el momento durante una Horda en concreto. La tabla que hemos diseñado y que da solución a esta consulta es la siguiente:

```sql
CREATE TABLE hordas(
    country VARCHAR,
    event_id INT,
    username VARCHAR,
    email VARCHAR,
    n_kills COUNTER,
    PRIMARY KEY ((country, event_id), email, username)
);
```

Para obtener los resultados de este ranking, se puede utilizar la siguiente consulta:

```sql
CONSISTENCY ONE;

SELECT username, email, n_kills
FROM hordas
WHERE country = <pais> AND event_id = <id_evento>
GROUP BY email
ORDER BY n_kills DESC
LIMIT <N>;
```

En este caso, utilizamos un nivel de consistencia de uno, ya que la consistencia en este leaderboard no es tan importante y, en cambio, el rendimiento es crítico.

#### Justificación

La clave de partición se compone de `country` y `event_id`. Dividir únicamente por `country` podría resultar en particiones demasiado grandes. Por el mismo motivo, hemos considerado que sería adecuado añadir `country` en lugar de utilizar únicamente `event_id`. 

Con respecto a la clave de clustering, es necesario utilizar `email` para poder identificar a cada usuario de manera única. No obstante, también añadimos `username` ya que, al utilizar el tipo de datos `COUNTER`, todas las columnas fuera de la clave primaria deben de utilizar este tipo de datos.

No añadimos `n_kills` a la clave de clustering puesto que es un campo que será actualizado y no deseamos tener más de un registo por usuario.

Para insertar datos en esta tabla, se puede utilizar la siguiente *query*:

```sql
CONSISTENCY ONE;

INSERT INTO kills_hordas (country, event_id, username, kills_counter)
VALUES (<pais>, <id_evento>, <nombre_usuario>, <número_de_muertes>)
USING TTL 86400;
```

Hemos utilizado un nivel de consistencia de `ONE` tal y como se recomienda en la [documentación](https://docs.datastax.com/en/archived/cql/3.0/cql/ddl/ddl_counters_c.html) de Cassandra cuando se utilizan contadores. Cassandra garantiza que los contadores se incrementen de manera consistente incluso si se producen escrituras concurrentes.

Por otro lado, hemos utilizado `TTL` para que los registros se eliminen automáticamente después de 24 horas. Esto es útil para evitar que la tabla crezca indefinidamente. Asumimos que no es necesario acceder a estos datos una vez ha terminado el evento, pero esto es una cuestión que debería ser aclarada con el equipo pertinente. Si se desea almacenar los datos de manera permanente, simplemente se puede eliminar dicha cláusula.

Para actualizar los datos de este ranking, se puede utilizar el siguiente *update*, cada vez que un usuario mata a un monstruo:

```sql
CONSISTENCY ONE;

UPDATE hordas
SET n_kills = n_kills + 1
WHERE country = <pais> 
    AND event_id = <id_evento> 
    AND email = <email_usuario>;
```

En cuanto a los tipos de datos utilizados, cabe destacar el uso de `COUNTER` para `n_kills`. Este tipo de datos es el más adecuado para este ranking ya que se trata de un contador que se incrementa cada vez que un usuario mata a un monstruo. De esta forma, evitamos tener que eliminar un registro y añadirlo de nuevo cada vez que un usuario mata a un monstruo, o tener que realizar agregaciones de tipo `COUNT` que podrían resultar en latencias innecesarias y que requerirían de un mayor número de escrituras y almacenamiento.

Para el resto de campos, simplemente hemos utilizado `VARCHAR` para las variables de tipo texto e `INT` para `event_id`. Este último tipo de datos es el que mejor se ajusta a las necesidades de este ranking ya que es posible que haya un gran número de eventos en el futuro.

## Tarea 2: exportación de ficheros CSV desde SQL

En esta sección se crean las consultas `.sql` necesarias para exportar los datos de la base de datos relacional a ficheros `.csv`. Los ficheros tienen un formato acorde al diseño anteriormente propuesto. Todas las consultas se encuentran en el fichero `export_queries.sql`. Aun así, a continuación se explican cada una de ellas:

### Hall of Fame

Para exportar los datos del *Hall of Fame* a un archivo `.csv`, necesitamos obtener los 5 mejores jugadores de cada mazmorra por país. Para ello, utilizamos la siguiente consulta:

```sql
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
```

Esta consulta comienza seleccionando campos relevantes de las tablas `WebUser` y `CompletedDungeons`, junto con la tabla `Dungeon` para obtener detalles específicos de las mazmorras completadas. Agrupa los resultados por usuario, mazmorra y país, y calcula el menor tiempo de finalización para cada combinación de usuario y mazmorra. 

Cabe destacar la utilización de la función de ventana `ROW_NUMBER()` para asignar un rango a cada registro dentro de cada país y mazmorra, basado en el tiempo de finalización más rápido y con un desempate por fecha en caso de tiempos idénticos. Finalmente, selecciona los cinco mejores registros de cada grupo para guardarlos en un archivo CSV, especificando los delimitadores de campos y líneas. El archivo resultante se guarda en la ruta especificada `/var/lib/mysql-files/HallofFame.csv`, con los campos encerrados en comillas.

### Estadísticas de usuario

Esta vez, migramos solamente el email, el ID de la mazmorra, el tiempo que ha tardado en completarlo y la fecha de completitud.

```sql
SELECT email, idD, time AS time_minute, date
FROM CompletedDungeons
ORDER BY email, idD, time_minute ASC
INTO OUTFILE '/var/lib/mysql-files/Statistics.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';
```

### Hordas

Obtenemos la información del país del usuario, el ID del evento (horda), el nombre de usuario, su identificador y el contador de muertes logrado por el usuario.

```sql
SELECT w.country, Kills.idE, w.userName, w.email, COUNT(*) AS n_kills
FROM Kills
JOIN WebUser AS w
    ON Kills.email = w.email
GROUP BY Kills.idE, w.country, w.userName, w.email
ORDER BY w.country ASC, Kills.idE ASC, n_kills DESC, w.userName ASC
INTO OUTFILE '/var/lib/mysql-files/Hordas.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';
```

## Tarea 3: creación del cluster

Definimos un `docker-compose.yml` que contiene la configuración necesaria para levantar un clúster de 3 nodos de Cassandra. Este fichero define un entorno con varias instancias de Apache Cassandra y un contenedor MySQL para la gestión de bases de datos. Cada servicio está configurado para interactuar dentro de una red definida como `cassandra` con controlador de red tipo `bridge`, lo que facilita la comunicación entre los contenedores en la misma red virtual.

## Tarea 4: fichero `.cql` con la carga de los datos desde SQL

El fichero `.cql` que crea el diseño en Cassandra y cargue los ficheros `.csv` creados en el paso 2 es `load.cql`. Se debe utiliza un factor de replicación de 2. Las pruebas se ejecutan en el clúster local definido en la tarea anterior.

Comenzaremos ejecutando el comando para llamar a `cqlsh` y modificaremos el *timeout* para no tener poblemas tanto en importación como exportación de los datos.

```sh
cqlsh --request-timeout=10000
```

Ahora, crearemos primero nuestro *keyspace*. El nombre que le daremos será *Dungeons*. Al estar ubicado en un mismo *datacenter* utilizaremos `SimpleStrategy` con un factor de replicación de 2.

```sql
CREATE KEYSPACE Dungeons 
WITH replication = {
    'class': 'SimpleStrategy', 
    'replication_factor': 2
};
```

Debido a que la migración no supone un estancamiento en el funcionamiento del juego, vamos a establecer una consistencia de tipo `ALL` en la etapa de migración para asegurarnos que empezamos con todos los datos en los nodos que hemos definido.

```sql
CONSISTENCY ALL;
```

Una vez hemos creado el *keyspace* y hemos establecido la consistencia, procedemos a crear las tablas de la misma forma que las hemos definido en la Tarea 1.

## Tarea 5: actualización de la tabla de escrituras

Esta tarea ya ha sido respondida en la Tarea 1 en las secciones de justificación de cada tabla.

## Tarea 6: fichero `.cql` con las consultas de escritura y lectura necesarias

Las consultas de escritura y lectura necesarias se encuentran en el fichero `read_and_write.cql`.

# Ejecución de la solución

## Pre-requisitos

Es necesario tener instalado Docker y Docker Compose en el sistema. Para instalar Docker, siga las instrucciones en la [documentación oficial](https://docs.docker.com/get-docker/). Para instalar Docker Compose, siga las instrucciones en la [documentación oficial](https://docs.docker.com/compose/install/).

Para desplegar y ejecutar la solución, se deben seguir los siguientes pasos:

## 1. Configuración del entorno

### 1.1 Levantar el clúster de Cassandra y MySQL

Desde la raíz del repositorio, ejecute el siguiente comando para levantar el clúster de Cassandra y MySQL:

```sh
cd cassandra && docker compose up --build
```

### 1.2 Verificar el estado del clúster

Opcionalmente, podemos verificar el estado del clúster de Cassandra ejecutando utilizando `nodetool`. Para ello primero debemos acceder a alguno de los nodos de Cassandra:

```sh
docker exec -it cassandra1 bash
```

Una vez dentro:

```sh
nodetool status
```

El resultado debería ser similar al siguiente:

```
Datacenter: MilkyWay
====================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address       Load        Tokens  Owns (effective)  Host ID                               Rack
UN  192.168.64.2  269.51 KiB  128     49.8%             2a07638d-f85f-4bb5-b893-6ad37f6ed8aa  R1  
UN  192.168.64.3  276.22 KiB  128     48.4%             488e455a-bda0-45ff-9425-a82b297c38a0  R1  
UN  192.168.64.4  319.11 KiB  128     52.0%             04ac025d-5c43-4d57-9468-6fb8b8323774  R1  
```

## 2. Exportar datos de MySQL a CSV

### 2.1. Conectarse a la base de datos MySQL

Para ello, podemos utilizar MySQL Workbench o cualquier otro cliente de MySQL como SQLTools para acceder desde Visual Studio Code. Para este último caso, se ha proporcionado la configuración necesaria dentro del fichero `.vscode/settings.json`. La conexión se realiza con los siguientes datos:

- Server: `localhost`
- Port: `3309`
- User: `root`
- Password: `root`
- Database: `dungeon`

### 2.2. Realizar el dump de los datos

Para ello, simplemente se debe de ejecutar el fichero `dumpVideogameMaster.sql` en el cliente de MySQL. Este fichero crea la base de datos SQL y las tablas necesarias para el juego así como inserta los datos necesarios para poder realizar las consultas de exportación a CSV.

### 2.3. Exportar los datos a CSV

Ejecutar las consultas SQL del fichero `export_queries.sql` en el cliente de MySQL.

## 3. Cargar los datos en Cassandra

### 3.1. Acceder a Cassandra

Utilizando el primer nodo, accedemos a Cassandra. Si ya nos encontrábamos dentro del contenedor, podemos ejecutar simplemente:

```sh
cqlsh --request-timeout=10000
```

Si no, podemos acceder al contenedor con el siguiente comando:

```sh
docker exec -it cassandra1 cqlsh --request-timeout=10000
```

### 3.2. Crear el keyspace y las tablas

Ejecutar el contenido del fichero `load.cql` en `cqlsh` para crear el keyspace y las tablas necesarias en Cassandra.