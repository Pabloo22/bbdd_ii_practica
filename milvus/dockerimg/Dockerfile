FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

ARG UID=1000
ARG GID=1000
ARG USER=angel

RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN addgroup --gid $GID $USER
RUN adduser --disabled-password --gecos '' --uid $UID --gid $GID $USER

USER $USER
WORKDIR /home/$USER
WORKDIR /home/$USER

USER root

RUN pip3 install torch
RUN pip install -qU \
    pymilvus \
    scipy \
    pandas \
    transformers==4.31.0 \
    accelerate==0.21.0 \
    einops==0.6.1 \
    pillow \
    xformers==0.0.20 \
    bitsandbytes==0.41.0

RUN pip3 install jupyter
RUN pip3 install jupyterlab

USER $USER

CMD ["bash", "-c", "source /etc/bash.bashrc && python -m jupyter lab --ip 0.0.0.0 --no-browser"]
