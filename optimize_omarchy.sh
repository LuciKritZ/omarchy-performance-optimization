#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LIMINE_CONF="/etc/default/limine"
MKINIT_CONF="/etc/mkinitcpio.conf"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root.${NC}"
   exit 1
fi

echo -e "${YELLOW}Starting System Optimization (Version 2 - Zswap Tuned)...${NC}"

# Install essential drivers and tools
echo -e "${GREEN}[1/6] Installing AMDGPU drivers, CPU tools, and memory modules...${NC}"
pacman -S --noconfirm --needed cpupower vulkan-radeon libva-mesa-driver mesa lz4

# Configure mkinitcpio modules (critical for zswap)
echo -e "${GREEN}[2/6] Configuring Kernel Modules (lz4, z3fold, amdgpu)...${NC}"
if [ -f "$MKINIT_CONF" ]; then
    # Backup
    cp "$MKINIT_CONF" "${MKINIT_CONF}.bak.$(date +%F_%H-%M)"
    
    # We need to ensure specific modules are loaded EARLY so Zswap can use them at boot
    # amdgpu (GPU), lz4 (Fast Compression), lz4_compress, z3fold (Allocator)
    
    # Ensure amdgpu is present
    if ! grep -q "amdgpu" "$MKINIT_CONF"; then
        sed -i 's/MODULES=(/MODULES=(amdgpu /' "$MKINIT_CONF"
        echo "   + Added amdgpu module"
    fi
    
    # Ensure lz4 and z3fold are present
    if ! grep -q "lz4" "$MKINIT_CONF"; then
        sed -i 's/MODULES=(/MODULES=(lz4 lz4_compress z3fold /' "$MKINIT_CONF"
        echo "   + Added lz4/z3fold modules"
    fi
else
    echo -e "${RED}Error: $MKINIT_CONF not found!${NC}"
fi

# Configure limine kernel parameters
echo -e "${GREEN}[3/6] Updating /etc/default/limine with Performance Flags...${NC}"

if [ -f "$LIMINE_CONF" ]; then
    cp "$LIMINE_CONF" "${LIMINE_CONF}.bak.$(date +%F_%H-%M)"

    # Enable swap
    if grep -q "zswap.enabled=0" "$LIMINE_CONF"; then
        sed -i 's/zswap.enabled=0/zswap.enabled=1/' "$LIMINE_CONF"
        echo "   ✔ Enabled Zswap (Changed zswap.enabled=0 to 1)"
    fi

    # Define flags
    # GPU: Force modern AMDGPU driver (Vulkan support)
    # ZSWAP: Force lz4 (fastest) and z3fold (efficient) and max 25% RAM usage
    PERF_FLAGS="loglevel=3 quiet splash radeon.si_support=0 radeon.cik_support=0 amdgpu.si_support=1 amdgpu.cik_support=1 zswap.enabled=1 zswap.compressor=lz4 zswap.zpool=z3fold zswap.max_pool_percent=25"
    
    # Apply flags
    # We replace the standard "quiet splash" with our supercharged string
    if grep -q "amdgpu.si_support=1" "$LIMINE_CONF"; then
        echo "   ℹ Parameters seem already present. Checking for updates..."
    else
        sed -i "s/quiet splash/$PERF_FLAGS/" "$LIMINE_CONF"
        echo "   ✔ Injected GPU + Zswap performance flags."
    fi
else
    echo -e "${RED}Error: $LIMINE_CONF not found!${NC}"
    exit 1
fi

# CPU governor settings
echo -e "${GREEN}[4/6] Setting CPU to 'Performance' mode...${NC}"
sed -i 's/#governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
sed -i 's/governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
systemctl enable --now cpupower.service
echo "   ✔ CPU governor locked to performance."

# Regenerate boot images
echo -e "${GREEN}[5/6] Regenerating Boot Images (This locks in the modules)...${NC}"
# Use the Limine specific tool
limine-mkinitcpio

# Final cleanup
echo -e "${GREEN}[6/6] Reloading Daemons...${NC}"
systemctl daemon-reload

echo -e "${GREEN}======================================================${NC}"
echo -e "${YELLOW}OPTIMIZATION COMPLETE!${NC}"
echo -e "1. Zswap is now configured for LOW LATENCY (lz4)."
echo -e "2. Vulkan is UNLOCKED (amdgpu)."
echo -e "3. CPU is UNCHAINED (performance governor)."
echo -e "4. Reboot now to apply changes."
echo -e "${GREEN}======================================================${NC}"
