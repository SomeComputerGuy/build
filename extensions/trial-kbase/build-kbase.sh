#!/bin/bash
# TRIAL ONLY: build Arm's Bifrost kbase (Rockchip develop-6.6 tree, g25p0-00eac0, JM UK 11.47) as an
# out-of-tree module for the sunxi64 edge 7.3 kernel. Never part of an image build.
# Usage: build-kbase.sh <kernel-headers-or-build-dir> <workdir>
#   e.g. a dpkg-deb -x of linux-headers-edge-sunxi64 (then: make scripts modules_prepare there first)
set -euo pipefail
KDIR=$(realpath "$1"); W=$(realpath -m "$2"); HERE=$(dirname "$(realpath "$0")")
RK_COMMIT=1ba51b059f25533c5529b7f68186190b47d6a7b3   # rockchip-linux/kernel develop-6.6, 2025-09-01
mkdir -p "$W"; cd "$W"
if [[ ! -d rk66 ]]; then
	git clone -q --filter=blob:none --sparse -b develop-6.6 https://github.com/rockchip-linux/kernel.git rk66
	git -C rk66 sparse-checkout set --no-cone drivers/gpu/arm/bifrost include/uapi/gpu/arm/bifrost \
		'/include/linux/version_compat_defs.h' '/include/linux/memory_group_manager.h' \
		'/include/linux/priority_control_manager.h' '/include/linux/protected_memory_allocator.h' \
		'/include/linux/protected_mode_switcher.h' '/include/linux/mali_*' drivers/base/arm
fi
git -C rk66 -c advice.detachedHead=false checkout -q $RK_COMMIT
rm -rf src; mkdir src; cp -a rk66/drivers rk66/include src/
python3 -I "$HERE/port-7.3.py" src/drivers/gpu/arm/bifrost
KREL=$(cat "$KDIR/include/config/kernel.release")
make -C src/drivers/gpu/arm/bifrost KDIR="$KDIR" ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-} \
	LOCALVERSION="${KREL#7.3.1}" CONFIG_MALI_BIFROST_DEVFREQ=n -j"$(nproc)"
modinfo -F vermagic src/drivers/gpu/arm/bifrost/bifrost_kbase.ko
