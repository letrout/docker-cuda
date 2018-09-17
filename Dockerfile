FROM ubuntu:18.04
LABEL maintainer="joelluth@gmail.com"

# gcc-5 for ubuntu 16.04
#ENV GCC_VER 5
# gcc-6 for ubuntu 18.04
ENV GCC_VER 6

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                ca-certificates \
                dirmngr \
                g++-${GCC_VER} \
                gcc-${GCC_VER} \
                git \
                gnupg-agent \
                initramfs-tools-ubuntu-core \
                libmodule-install-perl \
                linux-headers-$(uname -r) \
                software-properties-common \
                ubuntu-drivers-common \
                wget \
        && apt-get -y clean \
        && apt-get -y autoremove \
        && rm -rf /var/lib/apt/lists/*

ENV NVIDIA_DRIVER_VER 340
ENV CUDA_INSTALL cuda_9.2.88_396.26_linux
ENV CUDA_PATCH cuda_9.2.88.1_linux
# Insatll CUDA
RUN wget -c https://developer.nvidia.com/compute/cuda/9.2/Prod/local_installers/
${CUDA_INSTALL} \
        && chmod +x ${CUDA_INSTALL} \
        && ./${CUDA_INSTALL} --verbose --silent --toolkit --override \
        && rm -f ${CUDA_INSTALL}

ENV PATH ${PATH}:/usr/local/cuda-9.2/bin
RUN echo "/usr/local/cuda-9.2/lib64" >> /etc/ld.so.conf \
        && ldconfig

# Get any patches
RUN wget https://developer.nvidia.com/compute/cuda/9.2/Prod/patches/1/${CUDA_PAT
CH} \
        && chmod +x ${CUDA_PATCH} \
        && ./${CUDA_PATCH} --silent --accept-eula \
        && rm -f ${CUDA_PATCH}

# Create symlinks to gcc
RUN ln -s /usr/bin/gcc-${GCC_VER} /usr/local/cuda-9.2/bin/gcc \
        && ln -s /usr/bin/g++-${GCC_VER} /usr/local/cuda-9.2/bin/g++

# Install the driver
RUN add-apt-repository -y ppa:graphics-drivers/ppa
# Driver prompts for input, not sure how to workaround
#       && apt-get update \
#       && apt-get install -y --no-install-recommends \
#               nvidia-${NVIDIA_DRIVER_VER}
#       && apt-get -y clean \
#        && apt-get -y autoremove \
#        && rm -rf /var/lib/apt/lists/*
