FROM nvidia/cuda:13.0.0-devel-rockylinux9

# BUILD:    docker build --progress=plain --build-arg USER_ID=$(id -u) --build-arg USERNAME=$(id -un) -t lichtfeld-studio -f build.Dockerfile .
# RUN:      docker run --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0 -e NVIDIA_DRIVER_CAPABILITIES=compute,utility -it --name lichtfeld-studio lichtfeld-studio /bin/bash

ARG USER_ID
ARG USERNAME

RUN dnf upgrade -y \
    && dnf install -y epel-release \
    && dnf config-manager --set-enabled crb devel
    
RUN dnf groupinstall "Development Tools" -y && \
    dnf install -y \
    ca-certificates \
    gcc-toolset-14-gcc \
    gcc-toolset-14-gcc-c++ \
    git \
    gnupg2 \
    kernel-devel \
    libXcursor-devel \
    libxkbcommon-devel \
    libXi-devel \
    libXinerama-devel \
    libXrandr-devel \
    lsb_release \
    mesa-libGLU-devel \
    ninja-build \
    openssh-clients \
    perl-FindBin \
    perl-IPC-Cmd \
    perl-Time-Piece \
    pkgconf \
    python3 \
    python3-devel \
    python3-pip \
    sudo \
    unzip \
    wget \
    zenity \
    zip && \
    dnf clean all

RUN echo "Download and install CMake ..." && \
    wget https://github.com/Kitware/CMake/releases/download/v4.0.3/cmake-4.0.3-linux-x86_64.sh && \
    chmod +x cmake-4.0.3-linux-x86_64.sh && \
    ./cmake-4.0.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.0.3-linux-x86_64.sh
    
RUN useradd -u ${USER_ID} -m -s /bin/bash ${USERNAME} && \
    usermod -aG wheel "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/${USERNAME}
USER ${USERNAME}

RUN echo "Download and install libtorch ..." && \
    wget -q https://download.pytorch.org/libtorch/cu130/libtorch-shared-with-deps-2.9.0%2Bcu130.zip -O /tmp/libtorch.zip && \
    unzip /tmp/libtorch.zip -d /home/${USERNAME} && \
    rm /tmp/libtorch.zip

RUN echo "Download and install vcpkg ..." && \
    git clone https://github.com/microsoft/vcpkg.git /home/${USERNAME}/vcpkg && \
    cd /home/${USERNAME}/vcpkg && \
    ./bootstrap-vcpkg.sh -disableMetrics

RUN echo 'export VCPKG_ROOT=${HOME}/vcpkg' >> /home/${USERNAME}/.bashrc && \
    echo 'export PATH=$VCPKG_ROOT:$PATH' >> /home/${USERNAME}/.bashrc

RUN echo "Download and build LichtFeld-Studio ..." && \
    git clone https://github.com/MrNeRF/LichtFeld-Studio.git && \
    cd LichtFeld-Studio && \
    scl enable gcc-toolset-14 bash && \
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_PORTABLE=True \
        -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
        -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja \
        -G Ninja \
        -DCMAKE_CUDA_COMPILER=/usr/local/cuda-13.0/bin/nvcc \
        -DCMAKE_C_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/gcc \
        -DCMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/g++ && \
    cmake --build build -- -j$(nproc) && \
    cmake --install build --prefix install

