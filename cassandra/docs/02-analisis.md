<div align="center">

--- 

# Base de Datos II
## Práctica de Cassandra
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

Debido al aumento de la popularidad del juego, la base de usuarios y el número de países donde se vende el juego han aumentado significativamente. El equipo de operaciones ha notado que la base de datos relacional que usan no cumple con los objetivos de rendimiento ni de escalabilidad necesarios para dar soporte a los *leaderboards* del juego.

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

- **Alta disponibilidad:** la consistencia ya no es la prioridad, sino que se prioriza el rendimiento. De esta forma se evitan altos tiempos de carga a la hora de cargar los rankings, posibilitándose la visualización en tiempo real de ellos durante eventos como las Hordas.

- **Soporte para grandes volúmenes de escrituras:** las escrituras a disco se realizan en batches una vez la cantidad de memoria RAM utilizada ha sobrepasado cierta cantidad. De esta forma, se realiza una carga de los datos más eficiente al poder realizarse concurrentemente. Además, si varias operaciones de escritura se han recibido sobre un mismo registro únicamente este se actualiza con el que tenga el *timestamp* más reciente, reduciendo el número de datos a escribir en disco.

