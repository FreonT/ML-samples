
FROM nvcr.io/nvidia/tensorrt:19.12-py3
ENV DEBIAN_FRONTEND=noninteractive

ENV HOME /root
WORKDIR /root

RUN apt-get update -y && apt-get -y upgrade

# tmux, [1]
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tmux \
    vim

# pyenv,[2]
ENV PYTHON_VERSION 3.7.6
ENV PYTHON_ROOT $HOME/local/python-$PYTHON_VERSION
ENV PATH $PYTHON_ROOT/bin:$PATH
ENV PYENV_ROOT $HOME/.pyenv
RUN apt-get update && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
    git \
    make \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
 && git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT \
 && $PYENV_ROOT/plugins/python-build/install.sh \
 && /usr/local/bin/python-build -v $PYTHON_VERSION $PYTHON_ROOT \
 && rm -rf $PYENV_ROOT

RUN pip install --upgrade pip

# X window, options ----------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    vim xvfb x11vnc python-opengl

# Jupyter and options
RUN pip install setuptools jupyterlab==2
EXPOSE 8888
EXPOSE 5900

RUN pip install ipywidgets
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUn apt-get install -y nodejs
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN pip install xeus-python==0.6.13 notebook==6 ptvsd
RUN jupyter labextension install @jupyterlab/debugger
RUN pip install matplotlib

# tensorboard
RUN pip install --upgrade pip
RUN pip install tensorflow
RUN pip install tensorboardX
EXPOSE 6006

# pytorch
RUN pip install torch==1.4.0 torchvision==0.5.0
RUN pip install pixyz

# options
RUN pip install hydra-core --upgrade
RUN pip install ray
RUN pip install optuna

EXPOSE 8265

RUN echo 'Xvfb :0 -screen 0 1400x900x24 & ' >> /root/Xvfb-run.sh && \
    echo 'x11vnc -display :0 -passwd pass -forever &' >> /root/run-Xvfb.sh && \
    chmod +x /root/run-Xvfb.sh

RUN echo 'DISPLAY=:0 jupyter notebook --allow-root --ip=0.0.0.0 --port 8888 --notebook-dir=/root --NotebookApp.password="sha1:71247b1fba50:6334281a44d2134e85492be9ad7426a3cf9caf90" &' >> /root/run-jupyter.sh && \
    chmod +x /root/run-jupyter.sh

# auto start tmux and Xvfb, Jupyter
ENTRYPOINT tmux new \; \
            send-keys 'Xvfb :0 -screen 0 1400x900x24 & ' Enter \; \
	    send-keys 'x11vnc -display :0 -passwd 0123 -forever &' Enter \; \
            split-window -v  \; \
            send-keys "jupyter nbextension enable --py widgetsnbextension --sys-prefix" Enter \; \
            send-keys "bash /root/run-jupyter.sh" Enter \; \
	   new-window \; \
    	    send-keys clear C-m \;
