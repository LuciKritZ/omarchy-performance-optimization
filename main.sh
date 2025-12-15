#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/constants.sh"
source "$SCRIPT_DIR/utils/backup.sh"
source "$SCRIPT_DIR/modules/detect_hardware.sh"
source "$SCRIPT_DIR/modules/packages.sh"
source "$SCRIPT_DIR/modules/cpu.sh"
source "$SCRIPT_DIR/modules/memory.sh"
source "$SCRIPT_DIR/modules/bootloader.sh"

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Hardware Optimizer initialized"

detect_hardware
resolve_and_install_packages
configure_cpu
configure_memory

GPU_KERNEL_ARGS=""
if [ $IS_VIRT -eq 0 ]; then
    if [ "$HAS_AMD_GPU" = true ]; then
        GPU_KERNEL_ARGS="$GPU_KERNEL_ARGS radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1"
    fi
    if [ "$HAS_NVIDIA_GPU" = true ]; then
        GPU_KERNEL_ARGS="$GPU_KERNEL_ARGS nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
    fi
fi
configure_bootloader "$GPU_KERNEL_ARGS" "$MEMORY_KERNEL_ARGS"

build_images
