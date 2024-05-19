import os

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.image as mpimg


from pymilvus import (
    MilvusClient,
    DataType,
    FieldSchema,
    CollectionSchema,
    Collection,
)

from clip_embeddings_generator import ClipEmbeddingsGenerator


def draw_images(images_paths: list[str], titles: list[str]) -> None:
    """
    Draws images.
    :param images_paths: list of paths to images
    :param titles: list of titles for images
    """
    images = [mpimg.imread(path) for path in images_paths]

    if len(images_paths) == 1:
        plt.figure(figsize=(10, 5))
        plt.imshow(images[0])
        plt.title(titles[0])
        plt.axis("off")
    else:
        _, axs = plt.subplots(1, len(images), figsize=(10, 5 * len(images)))
        for i, (image, title) in enumerate(zip(images, titles)):
            axs[i].imshow(image)
            axs[i].set_title(title)
            axs[i].set_axis_off()


def create_client() -> MilvusClient:
    return MilvusClient(uri="http://milvus-standalone:19530")


def create_schema() -> CollectionSchema:
    fields = [
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=512),
        FieldSchema(name="id", dtype=DataType.INT64, is_primary=True),
    ]
    schema = CollectionSchema(fields, description="Avatar collection")

    return schema


def create_collection(
    client: MilvusClient,
    schema: CollectionSchema,
    collection_name: str,
    index_params: dict | None = None,
):
    if client.has_collection(collection_name):
        client.drop_collection(collection_name)

    metric_type = None if index_params is None else index_params["metric_type"]
    client.create_collection(
        collection_name,
        dimension=512,
        schema=schema,
        index_params=index_params,
        metric_type=metric_type,
    )


def load_images(
    embedder: ClipEmbeddingsGenerator,
    client: MilvusClient,
    collection_name: str,
    batch_size=1,
    image_dir="images/",
):
    image_paths = [
        os.path.join(image_dir, img)
        for img in os.listdir(image_dir)
        if img.endswith(".png")
    ]
    # Procesamos las imágenes en batches para evitar un OutOfMemoryError
    # (Nuestra gpu es de 4GB)
    image_embeddings: list[np.ndarray] = []
    for i in range(0, len(image_paths), batch_size):
        batch_paths = image_paths[i : i + batch_size]
        batch_embeddings = embedder.embedd_images(batch_paths)
        image_embeddings.extend(batch_embeddings)

    data = [
        {"id": i, "embedding": image_embeddings[i].tolist()}
        for i in range(len(image_embeddings))
    ]

    # collection.insert(entities)
    client.insert(collection_name=collection_name, data=data)


def create_index(
    client: MilvusClient, collection_name: str, config: dict | None = None
):
    # Check if the collection has an index and drop it if necessary
    indexes = client.list_indexes(collection_name)
    if indexes:
        client.release_collection(collection_name)
        client.drop_index(collection_name, index_name="")

    # Set default index parameters if not provided
    if config is None:
        config = {
            "metric_type": "L2",
            "index_type": "IVF_FLAT",
            "params": {"nlist": 32},
        }
    index_params = client.prepare_index_params(field_name="embedding", **config)
    # Create the index on the specified field
    client.create_index(collection_name, index_params=index_params)


def search_by_text_from_collection(
    loaded_collection: Collection,
    embedder: ClipEmbeddingsGenerator,
    text: str,
    top_k: int = 5,
    search_params: dict | None = None,
):
    text_embedding = embedder.embedd_texts([text])[0]
    if search_params is None:
        search_params = {"metric_type": "L2", "params": {"nprobe": 16}}

    results = loaded_collection.search(
        data=[text_embedding],
        anns_field="embedding",
        param=search_params,
        limit=top_k,
        expr=None,
    )
    return results


def search_by_text(
    client: MilvusClient,
    collection_name: str,
    embedder: ClipEmbeddingsGenerator,
    text: str,
    top_k: int = 5,
    search_params: dict | None = None,
):
    text_embedding = embedder.embedd_texts([text])[0]
    if search_params is None:
        search_params = {"metric_type": "L2", "params": {"nprobe": 16}}

    results = client.search(
        collection_name=collection_name,
        data=[text_embedding],
        anns_field="embedding",
        limit=top_k,
        params=search_params,
    )
    return results


def search_by_image_from_collection(
    loaded_collection: Collection,
    embedder: ClipEmbeddingsGenerator,
    image_path: str,
    top_k: int = 5,
    search_params: dict | None = None,
):
    image_embedding = embedder.embedd_images([image_path])[0]
    if search_params is None:
        search_params = {"metric_type": "L2", "params": {"nprobe": 16}}

    results = loaded_collection.search(
        data=[image_embedding],
        anns_field="embedding",
        param=search_params,
        limit=top_k,
    )
    return results


def search_by_image(
    client: MilvusClient,
    collection_name: str,
    embedder: ClipEmbeddingsGenerator,
    image_path: str,
    top_k: int = 5,
    search_params: dict | None = None,
):
    image_embedding = embedder.embedd_images([image_path])[0]
    if search_params is None:
        search_params = {"metric_type": "L2", "params": {"nprobe": 16}}

    results = client.search(
        collection_name=collection_name,
        data=[image_embedding],
        limit=top_k,
        params=search_params,
    )
    return results
