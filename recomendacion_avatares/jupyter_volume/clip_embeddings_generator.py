import numpy as np
import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
from typing import List


class ClipEmbeddingsGenerator:
    """
    Class for generating embeddings for images and texts using CLIP model.
    """

    def __init__(self) -> None:
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        self.model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(
            self.device
        )
        self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

    def embedd_images(self, images_paths: List[str]) -> np.ndarray:
        """
        Embedds images using CLIP model.
        :param images_paths: list of paths to images
        :return: embeddings of images
        """
        images = [Image.open(path) for path in images_paths]
        inputs = self.processor(images=images, return_tensors="pt", text=None).to(
            self.device
        )
        outputs = self.model.get_image_features(**inputs)
        return outputs.cpu().detach().numpy()

    def embedd_texts(self, texts: List[str]) -> np.ndarray:
        """
        Embedds texts using CLIP model.
        :param texts: list of image descriptions
        :return: embeddings of texts
        """
        inputs = self.processor(images=None, return_tensors="pt", text=texts).to(
            self.device
        )
        outputs = self.model.get_text_features(**inputs)
        return outputs.detach().cpu().numpy()
