#!/bin/bash

log_header "Detecting Hardware..."

CPU_VENDOR=""
TOTAL_RAM_GB=0
IS_VIRT=0

HAS_INTEL_GPU=false
HAS_AMD_GPU=false
HAS_NVIDIA_GPU=false

INSTALL_PACKAGES="cpupower linux-firmware lz4"
KERNEL_ARGS=""
MKINIT_MODULES=""

# Virtualization
if systemd-detect-virt > /dev/null; then
    IS_VIRT=1
    log_info_tab_spaced "-> Virtualization Detected: ${YELLOW}Yes ($(systemd-detect-virt))${NC}"
fi

CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    INSTALL_PACKAGES="$INSTALL_PACKAGES intel-ucode"
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    INSTALL_PACKAGES="$INSTALL_PACKAGES amd-ucode"
fi

TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

GPU_LIST=$(lspci | grep -E "VGA|3D|Display")

if echo "$GPU_LIST" | grep -iq "Intel"; then
    HAS_INTEL_GPU=true
fi
if echo "$GPU_LIST" | grep -iqE "AMD|ATI|Advanced Micro Devices"; then
    HAS_AMD_GPU=true
fi
if echo "$GPU_LIST" | grep -iq "NVIDIA"; then
    HAS_NVIDIA_GPU=true
fi

if [ $IS_VIRT -eq 1 ]; then
    # Virtual Machine
    INSTALL_PACKAGES="$INSTALL_PACKAGES xf86-video-vmware xf86-video-qxl"
else
    # Physical Machine
    if [ "$HAS_INTEL_GPU" = true ]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES vulkan-intel intel-media-driver libva-intel-driver mesa"
        MKINIT_MODULES="$MKINIT_MODULES i915"
    fi

    if [ "$HAS_AMD_GPU" = true ]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa"
        KERNEL_ARGS="$KERNEL_ARGS radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1"
        MKINIT_MODULES="$MKINIT_MODULES amdgpu"
    fi

    if [ "$HAS_NVIDIA_GPU" = true ]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland"
        KERNEL_ARGS="$KERNEL_ARGS nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
        MKINIT_MODULES="$MKINIT_MODULES nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    fi
fi

if [ "$TOTAL_RAM_GB" -ge 8 ]; then
    KERNEL_ARGS="$KERNEL_ARGS zswap.enabled=1 zswap.compressor=lz4 zswap.zpool=z3fold zswap.max_pool_percent=25"
else
    KERNEL_ARGS="$KERNEL_ARGS zswap.enabled=1 zswap.compressor=zstd zswap.zpool=z3fold zswap.max_pool_percent=20"
fi

log_info_tab_spaced "CPU: $CPU_VENDOR | RAM: ${TOTAL_RAM_GB}GB"
log_info_tab_spaced "GPUs Detected: Intel: $HAS_INTEL_GPU | AMD: $HAS_AMD_GPU | Nvidia: $HAS_NVIDIA_GPU"
