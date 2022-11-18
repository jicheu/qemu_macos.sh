#!/bin/bash
# Usage 
#  ./qemu.sh ubuntu-core-22-amd64.img x86_64 6G 3
# ./qemu.sh 

set -euo pipefail

IMAGE="${1-}"
ARCH="${2-x86_64}"
RAM="${3-4G}"
PROC="${4-2}"
IFACE=`route -n get 0.0.0.0 | grep interface | cut -d " " -f 4`
MACHINE="${5-}"
CPU="${6-}"

if [ -z "${IMAGE}" ]; then
    echo "Usage: ${0} image_name <arch>"
    exit -1
fi

if [ ! -f "${IMAGE}" ]; then
    echo "File does not exist: ${IMAGE}"
    exit -1
fi

echo "Using image: ${IMAGE}"

CMD="sudo qemu-system-${ARCH}  -smp ${PROC} \
 -m "${RAM}" \
 -netdev vmnet-bridged,id=vmnet,ifname=${IFACE} -device e1000-82540em,netdev=vmnet \
 -net user,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80  \
 -drive "file=${IMAGE}",if=none,format=raw,id=disk1 \
 -device virtio-blk-pci,drive=disk1,bootindex=1 \
 -serial mon:stdio" 

if [ "${ARCH}" == "x86_64" ]; then
	CMD="${CMD} -bios OVMF.bin"
elif [[ "${ARCH}" =~ ^(arm|aarch64)$ ]]; then
	CMD="${CMD} -machine ${MACHINE} -cpu ${CPU}"
fi

echo "Running command: ${CMD}"
exec ${CMD}
