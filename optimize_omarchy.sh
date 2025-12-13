#!/bin/bash

# ==============================================================================
# Omarchy Hardware Optimizer
# Universal setup for Limine + mkinitcpio
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LIMINE_CONF="/etc/default/limine"
MKINIT_CONF="/etc/mkinitcpio.conf"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Must run as root.${NC}"
   exit 1
fi

echo -e "${BLUE}:: Omarchy Hardware Optimizer initialized${NC}"

# 1. Hardware Detection
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Detecting system hardware...${NC}"

CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))

GPU_TYPE="UNKNOWN"
if lspci | grep -iE "VGA|3D" | grep -iq "NVIDIA"; then
    GPU_TYPE="NVIDIA"
elif lspci | grep -iE "VGA|3D" | grep -iq "Advanced Micro Devices"; then
    GPU_TYPE="AMD"
elif lspci | grep -iE "VGA|3D" | grep -iq "Intel"; then
    GPU_TYPE="INTEL"
fi

echo -e "   CPU: $CPU_VENDOR | GPU: $GPU_TYPE | RAM: ${TOTAL_RAM_GB}GB"

# 2. Package Selection
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: resolving dependencies...${NC}"

PACKAGES="cpupower linux-firmware lz4"

# Microcode
[[ "$CPU_VENDOR" == "GenuineIntel" ]] && PACKAGES="$PACKAGES intel-ucode"
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && PACKAGES="$PACKAGES amd-ucode"

# GPU Drivers & Modules
KERNEL_GPU_ARGS=""
MODULES_ADD=""

case $GPU_TYPE in
    "NVIDIA")
        PACKAGES="$PACKAGES nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland"
        KERNEL_GPU_ARGS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
        MODULES_ADD="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
        ;;
    "AMD")
        PACKAGES="$PACKAGES xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa"
        # Force Sea Islands / Southern Islands support
        KERNEL_GPU_ARGS="radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1"
        MODULES_ADD="amdgpu"
        ;;
    "INTEL")
        PACKAGES="$PACKAGES vulkan-intel intel-media-driver libva-intel-driver mesa"
        MODULES_ADD="i915"
        ;;
esac

pacman -S --noconfirm --needed $PACKAGES > /dev/null 2>&1

# 3. Kernel Parameter Configuration (Zswap + GPU)
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Configuring kernel parameters...${NC}"

# Dynamic Zswap Strategy
if [ "$TOTAL_RAM_GB" -ge 8 ]; then
    # Low Latency configuration
    ZSWAP_ARGS="zswap.enabled=1 zswap.compressor=lz4 zswap.zpool=z3fold zswap.max_pool_percent=25"
else
    # High Compression configuration
    ZSWAP_ARGS="zswap.enabled=1 zswap.compressor=zstd zswap.zpool=z3fold zswap.max_pool_percent=20"
fi

if [ -f "$LIMINE_CONF" ]; then
    cp "$LIMINE_CONF" "${LIMINE_CONF}.bak"
    FINAL_ARGS="loglevel=3 quiet splash $KERNEL_GPU_ARGS $ZSWAP_ARGS"
    
    # Injection via regex replacement of standard anchor
    if grep -q "quiet splash" "$LIMINE_CONF"; then
        sed -i "s/quiet splash.*/$FINAL_ARGS\"/" "$LIMINE_CONF"
    else
        sed -i "s/KERNEL_CMDLINE\[default\]=\"/KERNEL_CMDLINE[default]=\"$FINAL_ARGS /" "$LIMINE_CONF"
    fi
    echo -e "   Applied: $KERNEL_GPU_ARGS"
fi

# 4. Initramfs Configuration
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Updating mkinitcpio.conf...${NC}"

if [ -f "$MKINIT_CONF" ]; then
    cp "$MKINIT_CONF" "${MKINIT_CONF}.bak"
    
    # Clean up potentially unstable modules from previous configs
    sed -i -e 's/z3fold//g' -e 's/lz4_compress//g' -e 's/lz4//g' "$MKINIT_CONF"
    sed -i 's/  / /g' "$MKINIT_CONF"

    # Inject critical display modules
    for mod in $MODULES_ADD; do
        if ! grep -q "$mod" "$MKINIT_CONF"; then
            sed -i "s/MODULES=(/MODULES=($mod /" "$MKINIT_CONF"
        fi
    done
fi

# 5. Build & Sync
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Syncing kernel headers and regenerating images...${NC}"

# Reinstall linux to ensure module tree consistency before build
pacman -S --noconfirm linux > /dev/null 2>&1

# CPU Governor
sed -i 's/#governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
sed -i 's/governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
systemctl enable --now cpupower.service > /dev/null 2>&1

# Generate
if limine-mkinitcpio; then
    echo -e "${GREEN}:: Optimization successful.${NC}"
else
    echo -e "${RED}:: Build failed. Check logs.${NC}"
    exit 1
fi

systemctl daemon-reload
echo -e "${YELLOW}:: System reboot required.${NC}"
