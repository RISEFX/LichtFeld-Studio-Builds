#!/usr/bin/env bash

#
# Custom fixes and build/inistall steps for Version v0.5.0:
#
# 1. Create the directory '/python3.12' to install Python
# 2. Install LichtFeld-Studio
# 3. Copy files from 'python3.12' to install directory under 'lib'
# 4. Fix RPATH in library(-ies)
# 5. Fix wrong library path in run script
#

git clone --branch ${LFS_VERSION} --recursive --depth 1 https://github.com/MrNeRF/LichtFeld-Studio.git
cd LichtFeld-Studio
git submodule update --init --recursive

mv /tmp/vcpkg.json ./

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_PORTABLE=True \
    -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja \
    -G Ninja \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda-13.0/bin/nvcc \
    -DCUDA_DEVICE_DEBUG=OFF \
    -DCMAKE_C_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/g++

cmake --build build -- -j$(nproc)

# Prepare directory to install the Python build
sudo mkdir -p /python3.12
sudo chown ${USERNAME}:${USERNAME} /python3.12

cmake --install build --prefix install

# Copy manually installed Python files to the correct final LFS library
# directory, and fix manually the RPATH of library(-ies).
cp -r /python3.12 install/lib
patchelf --set-rpath '$ORIGIN' install/lib64/liblfs_python_runtime.so
sed -i 's/lib/lib64/' install/bin/run_lichtfeld.sh

# "ZIP final build of LichtFeld-Studio ..."
cd LichtFeld-Studio 
zip -r /tmp/LichtFeld-Studio-Portable-$(date -u +%Y%m%d)-${LFS_VERSION}.zip install/
