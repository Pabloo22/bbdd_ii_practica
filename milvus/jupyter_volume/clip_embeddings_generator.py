import numpy as np
import torch
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
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

    def embedd_images(self, images_paths: List[str]) -> np.array:
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

    def embedd_texts(self, texts: List[str]) -> np.array:
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


def draw_images(images_paths: List[str], titles: List[str]) -> None:
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
