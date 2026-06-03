FROM ubuntu:22.04

ENV TZ=UTC

RUN apt-get update  && \
        DEBIAN_FRONTEND=noninteractive apt install -y sudo build-essential gcc-aarch64-linux-gnu bison \
        qemu-user-static qemu-system-arm qemu-efi u-boot-tools binfmt-support \
        debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
        udev dosfstools uuid-runtime git-lfs device-tree-compiler python2 python3 \
        python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
        python3-distutils python3-pkg-resources swig libfdt-dev libpython3-dev dctrl-tools \
        pkg-config libncurses-dev lz4 cryptsetup liblz4-tool

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y genext2fs squashfs-tools f2fs-tools

RUN echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /workspace

CMD ["bash"]
