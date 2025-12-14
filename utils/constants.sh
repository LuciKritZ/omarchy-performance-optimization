#!/bin/bash

# File Paths
export LIMINE_CONF="/etc/default/limine"
export MKINIT_CONF="/etc/mkinitcpio.conf"

# Restore Utility Targets
export RESTORE_TARGETS=("/etc/default/limine" "/etc/mkinitcpio.conf")

# Managed Packages List for Restore Utility
export MANAGED_PACKAGES=(
    "cpupower" "lz4" "linux-firmware"
    "intel-ucode" "amd-ucode"
    "nvidia-dkms" "nvidia-utils" "lib32-nvidia-utils" "egl-wayland"
    "xf86-video-amdgpu" "vulkan-radeon" "libva-mesa-driver" "mesa"
    "vulkan-intel" "intel-media-driver" "libva-intel-driver"
    "xf86-video-vmware" "xf86-video-qxl"
)
