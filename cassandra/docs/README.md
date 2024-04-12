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

La tabla que hemos diseñado que da solución a esta consulta es la siguiente:

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

Con este diseño, todos los datos necesarios para la consulta anterior se pueden obtener mediante la siguiente consulta:

```sql
SELECT dungeon_id, dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado>
PER PARTITION LIMIT 5;
```

#### Justificación

La clave de partición se compone de `country` y `dungeon_id`. Esta elección se hace para garantizar que las consultas sean rápidas y no requieran buscar en múltiples particiones. De esta forma, nos aseguramos de que los datos para cada combinación de país y mazmorra estén localizados en el mismo nodo, reduciendo así la necesidad de realizar operaciones entre varios nodos.

Por otro lado, la clave de clustering `lowest_time` se utiliza para ordenar los resultados dentro de cada partición por el tiempo más bajo primero. Esto es crucial ya que permite una recuperación eficiente del top 5 de tiempos más bajos directamente de la base de datos, sin necesidad de procesamiento adicional o de ordenamiento en la aplicación cliente.

De esta forma, podemos utilizar `PER PARTITION LIMIT 5` para asegurarse de que sólo se devuelvan los cinco mejores registros por cada mazmorra dentro de un país. Este límite es manejado eficientemente por Cassandra, que puede aprovechar el ordenamiento físico de los datos dentro de la partición por la clave de clustering para cortar la búsqueda tan pronto como se obtienen los cinco mejores registros.

La adición de `email` a la clave de clustering nos permite poder identificar cada entrada de manera unica. Esto es especialmente importante, puesto que, la aplicación debe evitar la adición de más de una entrada para un mismo usuario. En caso contrario, es posible que un mismo usuario aparezca múltiples veces en un mismo ranking. A continuación, se muestra la lógica que debe seguir la aplicación a la hora de realizar escrituras:

1. Comprobar si su tiempo está en el top 5 para la mazmorra y país correspondiente:

```sql
SELECT dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado> AND dungeon_id = <dungeon_id>
LIMIT 5;
```

Esta query no requiere de un nivel de consistencia alto, puesto que 

Si el tiempo nuevo está en el top 5 (pocos casos):

2. Comprobar si el usuario está en la tabla para esa mazmorra (consistencia ALL)
3. Actualizar o añadir la entrada (consistencia ALL)


