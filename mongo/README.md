<div align="center">

--- 

# Base de Datos II
## Práctica de MongoDB
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

# Enunciado

Le empresa de “Norsewind Studios” tiene una wiki de su videojuego “Jotun’s Lair” que contiene información y lore sobre los monstruos, el loot del juego y las mazmorras. Además, permite a los usuarios dejar comentarios sobre su experiencia con el videojuego. Los usuarios pueden dejar comentarios sobre las siguientes temáticas:

- Lore: Teorías e información relacionadas con la historia del juego.
- Hint: Trucos y consejos para otros jugadores.
- Suggestion: Sugerencias de los usuarios para mejorar algún aspecto del juego.
- Bug: Reportes de posibles fallos que ocurren durante el gameplay.

La empresa tiene una API REST para dar servicio a la wiki. Hasta ahora, se viene usando una base de datos relacional, pero últimamente, debido al alto volumen de jugadores, el sistema se está viendo sobre saturado. Por esa razón, se ha decidido migrar de una base de datos relacional a una base de datos de documentos para probar si así se solventan los problemas. A continuación, las entidades de la base de datos relacional que estarán involucradas en el prototipo

<p align="center">
  <img src="./diagrama_er.png" alt="Schema" width="500"/>
</p>
<p align="center">
  Bases de datos relacional que da servicio a la wiki del juego. La parte coloreada es la parte que usaremos en esta práctica.
</p>

# Configuración del entorno

## Despliegue del contenedor

Para desplegar el contenedor de MongoDB, se debe ejecutar el siguiente comando:

```bash
docker compose up
```

Una vez desplegado, se puede acceder,mediante MongoDB Compass, a la base de datos en `localhost:27017`.

## Carga de la base de datos

Para cargar la base de datos, desde MongoDB Compass, se debe crear una nueva base de datos llamada `dungeons` y cuatro colecciones:

- loot
- monster
- rooms
- users

Una vez creadas, se deben importar los datos de los ficheros `loot.json`, `monster.json`, `rooms.json` y `users.json` en las colecciones correspondientes. Para ello se puede utilizar MongoDB Compass o el script [`load_data.py`](load_data.py)

# Tareas

## Python
Las queries en Python se encuentran en el siguiente [notebook](./queries_mongo.ipynb).

## MongoDB Compass

### Parte I

Para dar servicio a los jugadores y al equipo de quality assurance, se ha decidido crear una colección nueva en la base de datos que contenga todos los comentarios. Sigue estos pasos:

#### A: Exportar Datos a un Fichero .json

Realiza una consulta que obtenga los datos necesarios para la nueva colección y exporta el resultado a un fichero `.json`. A continuación, se proporciona la estructura de la colección.

```json
{
  "Creation_date": "str",
  "HintText": "str",
  "Category": "str",
  "References_room": {
    "IdR": "int",
    "Name": "str",
    "IdD": "int",
    "Dungeon": "str"
  },
  "Publish_by": {
    "Email": "str",
    "User_name": "str",
    "CreationDate": "str",
    "Country": "str"
  }
}
```

#### B: Crear y Poblar la Nueva Colección

1. Crea una nueva colección llamada `Hints`.
Pipeline:
```js
[
  {
    $unwind: "$hints"
  },
  {
    $group: {
      _id: null,
      data: {
        $push: {
          Creation_date: "$creation_date",
          HintText: "$hints.text",
          Category: "$hints.category",
          References_room:
            "$hints.referemces_room",
          Publish_by: {
            Email: "$email",
            User_name: "$user_name",
            Creation_date: "$creation_date",
            Country: "$country"
          }
        }
      }
    }
  },
  {
    $unwind: "$data"
  },
  {
    $replaceRoot: {
      newRoot: "$data"
    }
  }
]
```
2. Usa el fichero `.json` exportado en el paso anterior para poblar la colección `Hints`.
3. Elimina el campo `hints` de las colecciones `Rooms` y `User`.

#### C: Actualizar Endpoints

Actualiza las funciones de los siguientes endpoints:

- `POST /comment`
- `GET /dungeon/{dungeon_id}`
- `GET /room/{room_id}`
- `GET /user/{email}`

##### Impacto en los Endpoints

TODO

### Parte II

Realiza las siguientes consultas para el equipo de marketing

#### A. Número de cuentas de usuario que se crearon cada año agrupadas por país.

```js
[
  {
    $group: {
      _id: {
        $substr: ["$creation_date", 0, 4]
      },
      country: {
        $push: "$country"
      }
    }
  },
  {
    $unwind: "$country"
  },
  {
    $group: {
      _id: {
        year: "$_id",
        country: "$country"
      },
      count: {
        $sum: 1
      }
    }
  },
  {
    $group: {
      _id: "$_id.year",
      countries: {
        $push: {
          country: "$_id.country",
          count: "$count"
        }
      }
    }
  }
]
```

#### B. Los 20 países cuyos usuarios han realizado el mayor número de posts de tipo Lore en los últimos 5 años. Los países deben aparecen ordenados de mayor a menor número de posts.

TODO

#### C.  Los 5 usuarios que más bugs han reportado en 2022. Deben aparecer ordenados de mayor a menor.

```js
[
  {
    $unwind: "$hints"
  },
  {
    $match: {
      "hints.category": "bug"
    }
  },
  {
    $group: {
      _id: "$email",
      bugs_reported: {
        $sum: 1
      }
    }
  },
  {
    $sort:
      {
        bugs_reported: -1
      }
  }
]
```

#### D. La mazmorra que más sugerencias ha recibido desglosada en países.

```js
[
  {
    $unwind: "$hints"
  },
  {
    $match: {
      "hints.category": "suggestion"
    }
  },
  {
    $group:
      {
        _id: {
          country: "$hints.publish_by.country",
          dungeon_name: "$dungeon_name"
        },
        count: {
          $sum: 1
        }
      }
  },
  {
    $group: {
      _id: "$_id",
      max: {
        $max: "$count"
      }
    }
  }
]
```


