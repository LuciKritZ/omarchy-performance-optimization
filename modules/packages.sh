#!/bin/bash

resolve_and_install_packages() {
    log_header "Resolving dependencies..."
    
    local INSTALL_PACKAGES="cpupower linux-firmware lz4"

    # CPU Microcode
    if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES intel-ucode"
    elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES amd-ucode"
    fi

    # GPU Drivers
    if [ $IS_VIRT -eq 1 ]; then
        INSTALL_PACKAGES="$INSTALL_PACKAGES xf86-video-vmware xf86-video-qxl"
    else
        [ "$HAS_INTEL_GPU" = true ] && INSTALL_PACKAGES="$INSTALL_PACKAGES vulkan-intel intel-media-driver libva-intel-driver mesa"
        [ "$HAS_AMD_GPU" = true ] && INSTALL_PACKAGES="$INSTALL_PACKAGES xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa"
        [ "$HAS_NVIDIA_GPU" = true ] && INSTALL_PACKAGES="$INSTALL_PACKAGES nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland"
    fi

    log_info "Installing: $INSTALL_PACKAGES"
    pacman -S --noconfirm --needed $INSTALL_PACKAGES > /dev/null 2>&1
}
