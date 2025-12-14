#!/bin/bash

detect_hardware() {
    log_header "Detecting Hardware..."

    export CPU_VENDOR=""
    export TOTAL_RAM_GB=0
    export IS_VIRT=0
    export HAS_INTEL_GPU=false
    export HAS_AMD_GPU=false
    export HAS_NVIDIA_GPU=false

    # Virtualization
    if systemd-detect-virt > /dev/null; then
        IS_VIRT=1
        log_info "-> Virtualization Detected: ${YELLOW}Yes ($(systemd-detect-virt))${NC}"
    fi

    # CPU
    CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')

    # RAM
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

    # GPU
    local GPU_LIST=$(lspci | grep -E "VGA|3D|Display")
    echo "$GPU_LIST" | grep -iq "Intel" && HAS_INTEL_GPU=true
    echo "$GPU_LIST" | grep -iqE "AMD|ATI|Advanced Micro Devices" && HAS_AMD_GPU=true
    echo "$GPU_LIST" | grep -iq "NVIDIA" && HAS_NVIDIA_GPU=true

    log_info "CPU: $CPU_VENDOR | RAM: ${TOTAL_RAM_GB}GB"
    log_info "GPUs Detected: Intel: $HAS_INTEL_GPU | AMD: $HAS_AMD_GPU | Nvidia: $HAS_NVIDIA_GPU"
}
