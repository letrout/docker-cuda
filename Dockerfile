ROM ubuntu:16.04

# Ref https://docs.nvidia.com/deeplearning/sdk/cudnn-install/index.html#installcuda
# gcc-5 for ubuntu 16.04
#ENV GCC_VER 5
# gcc-6 for ubuntu 18.04
ENV GCC_VER 5

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
                make \
                software-properties-common \
                ubuntu-drivers-common \
                wget \
        && apt-get -y clean \
        && apt-get -y autoremove \
        && rm -rf /var/lib/apt/lists/*

ENV NVIDIA_DRIVER_RUN NVIDIA-Linux-x86_64-340.107.run
# note that 304.107 is installed in the host, so we can't use dirver extracted from CUDA
#ENV CUDA_INSTALL cuda_9.2.88_396.26_linux
#COPY NVIDIA-Linux-x86_64-340.107.run /root
RUN wget -c http://us.download.nvidia.com/XFree86/Linux-x86_64/340.107/${NVIDIA_DRIVER_RUN} \
        && chmod +x ./${NVIDIA_DRIVER_RUN} \
        && ./${NVIDIA_DRIVER_RUN} -a -s --no-kernel-module \
        && rm -f ${NVIDIA_DRIVER_RUN}

ENV CUDA_VER 6.5
ENV CUDA_INSTALL cuda_6.5.14_linux_64.run
ENV CUDA_PATCH cuda_9.2.88.1_linux
# Insatll CUDA
#RUN wget -c https://developer.nvidia.com/compute/cuda/9.2/Prod/local_installers/${CUDA_INSTALL} \
# note that 304.107 is installed in the host, so we can't use dirver extracted from CUDA
#       && ./NVIDIA-Linux-x86_64-340.29.run -s -N --no-kernel-module \
WORKDIR /root
RUN wget -c http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/${CUDA_INSTALL} \
        && chmod +x ${CUDA_INSTALL} \
        && mkdir cuda_install \
        && ./${CUDA_INSTALL} -extract=`pwd`/cuda_install \
        && cd cuda_install \
        && ./cuda-linux64-rel-6.5.14-18749181.run -noprompt \
        && ./cuda-samples-linux-6.5.14-18745345.run -noprompt -cudaprefix=/usr/local/cuda-6.5 \
        && cd ../ \
        && rm -rf cuda_install \
        && rm -f ${CUDA_INSTALL}

#ENV PATH ${PATH}:/usr/local/cuda-9.2/bin
ENV PATH ${PATH}:/usr/local/cuda-${CUDA_VER}/bin
#ENV LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-${CUDA_VER}/lib64
RUN echo "/usr/local/cuda-${CUDA_VER}/lib64" >> /etc/ld.so.conf \
        && ldconfig

# Get any patches
#RUN wget https://developer.nvidia.com/compute/cuda/9.2/Prod/patches/1/${CUDA_PATCH} \
#       && chmod +x ${CUDA_PATCH} \
#       && ./${CUDA_PATCH} --silent --accept-eula \
#       && rm -f ${CUDA_PATCH}

# Create symlinks to gcc
RUN ln -s /usr/bin/gcc-${GCC_VER} /usr/local/cuda-${CUDA_VER}/bin/gcc \
        && ln -s /usr/bin/g++-${GCC_VER} /usr/local/cuda-${CUDA_VER}/bin/g++

# Build deviceQuery
RUN cd /usr/local/cuda/samples/1_Utilities/deviceQuery \
        && make \
        && mv ./deviceQuery /usr/local/bin \
        && make clean

# Install cudnn
COPY cudnn-6.5-linux-x64-v2.tgz /root
RUN tar -xf cudnn-6.5-linux-x64-v2.tgz \
        && cp cudnn-6.5-linux-x64-v2/cudnn.h /usr/local/cuda/include/ \
        && cp cudnn-6.5-linux-x64-v2/libcudnn_static.a  /usr/local/cuda/lib64/ \
        && cp cudnn-6.5-linux-x64-v2/libcudnn.so.6.5.48 /usr/local/cuda/lib64/ \
        && rm -rf cudnn-6.5-linux-x64-v2
RUN ln -s /usr/local/cuda/lib64/libcudnn.so.6.5.48 /usr/local/cuda/lib64/libcudnn.so.6.5 \
        && ln -s /usr/local/cuda/lib64/libcudnn.so.6.5 /usr/local/cuda/lib64/libcudnn.so \
        && chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
RUN ldconfig
# Build mnistCUDNN
COPY cudnn-sample-v2.tgz /root
RUN tar -xf cudnn-sample-v2.tgz \
        && cd cudnn-sample-v2 \
        && make \
        && cp mnistCUDNN /usr/local/bin \
        && rm -rf cudnn-sample-v2

# Install the driver
#RUN add-apt-repository -y ppa:graphics-drivers/ppa
# Driver prompts for input, not sure how to workaround
#       && apt-get update \
#       && apt-get install -y --no-install-recommends \
#               nvidia-${NVIDIA_DRIVER_VER}
#       && apt-get -y clean \
#        && apt-get -y autoremove \
#        && rm -rf /var/lib/apt/lists/*

CMD ["/usr/local/bin/mnistCUDNN"]                                              