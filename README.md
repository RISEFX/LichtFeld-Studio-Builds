# Builds for LichtFeld-Studio

This repository builds automatically a portable version of LichtFeld-Studio for AlmaLinux 9 / RockyLinux 9.

**Command to build LichtFeld-Studio locally:**
```bash
docker build --progress=plain --build-arg USER_ID=$(id -u) --build-arg USERNAME=$(id -un) -f build_for_rockylinux9.Dockerfile -t lichtfeld-studio .
```

**Command to run a LichtFeld-Studio container locally to build Lichtfeld-Studio:**
```bash
docker run -it --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0 -e NVIDIA_DRIVER_CAPABILITIES=compute,utility --name lichtfeld-studio lichtfeld-studio /bin/bash

./build_lichtfeld_studio.sh
```

**Command to copy final build of LichtFeld-Studio to host maschine:**
```bash
docker cp lichtfeld-studio:/tmp/LichtFeld-Studio-Portable-$(date -u +%Y%m%d)-v0.5.2.zip /tmp
```
