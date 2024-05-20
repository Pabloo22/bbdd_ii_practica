from pymongo import MongoClient
from pymongo import collection
import json


# Conectar a MongoDB
client: MongoClient = MongoClient("mongodb://localhost:27017/")

# Crear la base de datos 'dungeons'
db = client["dungeons"]

# Crear las colecciones
loot_collection = db["loot"]
monster_collection = db["monster"]
rooms_collection = db["rooms"]
users_collection = db["users"]


def import_json_to_collection(file_path: str, collection_: collection.Collection):
    """Función para importar datos desde un archivo JSON a una colección"""
    with open(file_path, encoding="utf-8") as file:
        data = json.load(file)
        if isinstance(data, list):
            collection_.insert_many(data)
        else:
            collection_.insert_one(data)


# Importar los datos
FOLDER_PATH = "mongo/json_files/"
import_json_to_collection(f"{FOLDER_PATH}loot.json", loot_collection)
import_json_to_collection(f"{FOLDER_PATH}monster.json", monster_collection)
import_json_to_collection(f"{FOLDER_PATH}users.json", users_collection)
import_json_to_collection(f"{FOLDER_PATH}rooms.json", rooms_collection)

print("Datos importados con éxito!")
