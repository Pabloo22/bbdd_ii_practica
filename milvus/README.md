<div align="center">

--- 

# Base de Datos II
## Práctica de MongoDB
### Pablo Ariño, Álvaro Laguna, Jorge de la Rosa
### Ciencia de Datos e Inteligencia Artificial
<img src=https://www.upm.es/sfs/Rectorado/Gabinete%20del%20Rector/Logos/UPM/Logotipo%20con%20Leyenda/LOGOTIPO%20leyenda%20color%20PNG.png width=25% height=25%>

---
</div>

# Configuración del entorno

## Despliegue del contenedor

Para desplegar los contenedores necesarios, se debe ejecutar el siguiente comando:

```bash
docker compose up
```

Una vez desplegado, se puede acceder al jupyter lab, a la base de datos en `localhost:8899` con el token `milvus`.

# Tareas

Se han creado una serie de notebooks en la carperta [`jupyter_volume`](jupyter_volume) que contienen las tareas realizadas en la práctica. La funciones que utilizan estos notebooks se encuentran en los archivos `.py` de esta carpeta.

## Cargar los embeddings en la base de datos vectorial + Flujo de trabajo 2

Ver el notebook [`jupyter_volume/1_carga_datos.ipynb`](jupyter_volume/1_carga_datos.ipynb) para ver cómo se han cargado los embeddings en la base de datos vectorial. Además, se ha realizado un flujo de trabajo 2, en el que se permite, mediante una descripción textual, buscar los embeddings más cercanos a la descripción.

## Flujo de trabajo 1

Ver el notebook [`jupyter_volume/2_image_workflow.ipynb`](jupyter_volume/2_image_workflow.ipynb) para ver cómo se ha realizado el flujo de trabajo 1, en el que se permite buscar imágenes similares a una imagen dada.

## Pruebas de rendimiento

Ver el notebook [`jupyter_volume/3_pruebas_rendimiento.ipynb`](jupyter_volume/3_performance_tests.ipynb) para ver cómo se han realizado las pruebas de rendimiento de la base de datos vectorial, así como las conclusiones obtenidas.
