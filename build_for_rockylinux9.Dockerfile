FROM nvidia/cuda:13.0.0-devel-rockylinux9

# This Dockerfile can be used to build a portable version of Lichtfeld-Studio
# for AlmaLinux 9 or Rocky Linux 9 systems within a GitHub CI process or on a
# local workstation.

ARG LFS_VERSION=v0.5.2
ARG USER_ID
ARG USERNAME

RUN dnf upgrade -y \
    && dnf install -y epel-release \
    && dnf config-manager --set-enabled crb devel
    
RUN dnf groupinstall "Development Tools" -y && \
    dnf install -y \
    autoconf271 \
    autoconf-archive \
    ca-certificates \
    gcc-toolset-14-gcc \
    gcc-toolset-14-gcc-c++ \
    git \
    gnupg2 \
    kernel-devel \
    libX11-devel \
    libXcursor-devel \
    libXext-devel \
    libXft-devel \
    libXfixes-devel \
    libXi-devel \
    libXinerama-devel \
    libxkbcommon-devel \
    libXrandr-devel \
    libXtst-devel \
    lsb_release \
    mesa-libGLU-devel \
    nano \
    nasm \
    ninja-build \
    openssh-clients \
    patchelf \
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

USER ${USERNAME}
WORKDIR /home/${USERNAME}

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

# The version for SDL and ImGUI needs to be specified to a specific version!
COPY --chmod=755 --chown=${USERNAME}:${USERNAME} ./portable_fixes.patch /tmp/portable_fixes.patch

# It isn't possible to build LichtFeld-Studio directly in a Docker `build` call,
# because the build process needs NVIDIA CUDA libraries which are only available
# after starting a container with the NVIDIA runtime container library.
COPY --chmod=755 --chown=${USERNAME}:${USERNAME} ./build_lichtfeld_studio.sh build_lichtfeld_studio.sh

RUN echo 'source /opt/rh/autoconf271/enable' >> /home/${USERNAME}/.bashrc && \
    echo 'source /opt/rh/gcc-toolset-14/enable' >> /home/${USERNAME}/.bashrc

ENV USERNAME=${USERNAME}
ENV LFS_VERSION=${LFS_VERSION}
