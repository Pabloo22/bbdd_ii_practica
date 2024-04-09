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
Se pide el “hall of fame” de cada país, es decir, para un país concreto se muestran para cada mazmorra del juego el TOP 5 de jugadores más rápidos de ese país, incluyendo sus tiempos.

En este caso, se trata de una consulta algo compleja para lo que Cassandra no se encuentra del todo preparada. El principal problema es que, a priori, se debe de realizar una operación de tipo *group by* entre cada una de las mazmorras. En SQL, la query que resolvería este problema, probablemente fuese similar a la siguiente:

1. Seleccionar todos los usuarios del país indicado (ej. España):

```SQL
SELECT email, userName
FROM WebUser
WHERE country = "es_ES"
```

1. Realizar un *join* con la tabla *CompletedDungeons* y *Dungeon*, y agrupar por persona quedándonos con su menor tiempo:

```SQL
SELECT w.email, userName, idD, MIN(time) lowestTime, date, name dungeonName
FROM WebUser w
JOIN CompletedDungeons cd ON cd.email = w.email 
JOIN Dungeon d on cd.idD = d.idD
GROUP BY w.email
WHERE country = "es_ES"
```

3. Agrupar los resultados por mazmorra y ordenar por tiempos:

```SQL
SELECT email, userName, idD, lowest_time, date, name as dungeonName
FROM WebUser w
JOIN CompletedDungeons cd ON cd.email = w.email 
JOIN Dungeon d on cd.idD = d.idD 
WHERE country = "es_ES"
GROUP BY d.idD
ORDER BY d.idD, lowest_time
```
