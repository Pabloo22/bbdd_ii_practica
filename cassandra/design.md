<div align="center">

--- 

# Base de Datos II
## Práctica de Cassandra
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

# Diseño

## Hall of Fame

Se pide el “hall of fame” de cada país, es decir, para un país concreto se muestran para cada mazmorra del juego el TOP 5 de jugadores más rápidos de ese país, incluyendo sus tiempos.

Es importante remarcar que del enunciado no está claro si puede haber o no más de una entrada por usuario en un mismo *leaderboard*. Es decir, si la persona A ha realizado el mejor tiempo finalizando la mazmorra en 6 min una vez, y otra segunda vez en 7 min; y la persona B ha conseguido un tiempo de 8 min. Si se permite entradas repetidas el ranking quedaría A (6 min) > A (7 min) > B (8 min) > ... En caso contrario el ranking sería simplemente A (6 min) > B (8 min) > ... Al ser algo habitual en el contezto de *speed runs*, nosotros hemos asumido la opción que permite repeticiones como válida. No obstante, también se proporcionan soluciones en el caso de que se requiera de una única entrada por usuario.

Antes de exponer el diseño recomendado, vamos a hacer un resumen de otras posibles alternativas. Es importante recordar, sin embargo, que la mejor solución dependerá en gran medida del volumen real de escrituras y lecturas de los usuarios, así como de las capacidades del clúster. Puesto que estas métricas son imposibles de determinar actualmente, especialmente al tratarse de una situación hipotética, la solución que nosotros proponemos podría no ser la más adecuada. Es este el motivo por el cual no nos centraremos en una única soluciçon, si no que se plantean los diferentes desafíos y se estudian las ventajas y desventajas de cada una de las decisiones.


Una de las grandes limitaciones de Cassandra es que no nos permite utilizar operaciones de agregado de forma eficiente. Esto hace que en muchos casos sea necesario delegar a la aplicación el manejo de la lógica de ciertos aspectos. De esta forma, se puede conseguir una funcionalidad extra sin una pérdida de eficiencia. El coste, por supuesto, es una mayor complejidad del tratamiento de los datos, con sus respectivas consecuencias, como una mayor probabilidad de introducción de errores. A continuación, se muestra la que creemos que es la única solución que no requeriría de ninguna lógica. Esperamos que las limitaciones que esta tabla presenta sirvan para justificar el uso de esta lógica.

### Alternativa 1: no usar lógica de aplicación

En Cassandra, es posible realizar una consulta que nos devuelva un ranking. Para ello, los datos deben encontrarse ordenados por la métrica deseada y se debe aplicar la cláusula `LIMIT` para devolver únicamente el número de registros deseados.

A continuación, se muestra la tabla que se podría construir, así como las consultas de escritura y lectura necesarias:

**Tabla:**

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

Con respecto a los tipos de datos utilizados en cada columna, las variables de tipo texto se han definido como `VARCHAR`, ya que no que se requiere de más espacio en memoria para estas. Por otro lado, sobre `lowest_time`, si bien estimamos que se tardará menos de 127 min en completar en una mazmorra, ya que, tras un estudio de los datos, ninguno de los jugadores a ha tardado más de 49 minutos. En el futuro es posible que se diseñen mazmorras con una duración muy larga, y, por tanto, creemos que es más conservador utilizar el tipo `SMALLINT`, el cual nos permite almacenar enteros de hasta 32767. De la misma forma, es posible que en un futuro se amplie el número de mazzmorras a más de las 19 mazmorras actuales, superando las 127, por lo que, de nuevo, usamos `SMALLINT` para la columna `dungeon_id`.

#### Escrituras:

Cada vez que un usario completa una mazmorra, se añadiría una fila a la tabla:

```sql
CONSISTENCY ONE;

INSERT INTO hall_of_fame (
    country,
    dungeon_id,
    dungeon_name,
    email,
    username,
    lowest_time,
    date
) VALUES (
    <pais>,
    <dungeon_id>,
    <dungeon_name>,
    <email>,
    <username>,
    <lowest_time>,
    now()
)
```

Al añadirse una fila por cada finalización de mazmorra, se tendrá un número
muy elevado de entradas. Esto nos obliga a utilizar como clave de partición, no
solo el país, sino también el id de la mazmorra. De esta forma se consigue
reducir el tamaño de las particiones.

#### Lecturas:

Puesto que hemos incluido `dungeon_id` en la clave de partición, es necesario realizar
tantas consultas como mazmorras haya en el juego:

```sql
CONSISTENCY ONE;

SELECT dungeon_id, dungeon_name, email, username, lowest_time, date
FROM hall_of_fame
WHERE country = <pais_deseado> AND dungeon_id = <dungeon_id>
```

#### Problemas

La principal ventaja de este diseño es su sencillez.


