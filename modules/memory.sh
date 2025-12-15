#!/bin/bash

configure_memory() {
    log_header "Configuring memory performance..."

    if [ "$TOTAL_RAM_GB" -ge 8 ]; then
        export MEMORY_KERNEL_ARGS="zswap.enabled=1 zswap.compressor=lz4 zswap.zpool=z3fold zswap.max_pool_percent=25"
    else
        export MEMORY_KERNEL_ARGS="zswap.enabled=1 zswap.compressor=zstd zswap.zpool=z3fold zswap.max_pool_percent=20"
    fi
    log_info "Generated Zswap kernel arguments."

    local swappiness_conf="/etc/sysctl.d/99-omarchy-ram.conf"

    if [ ! -d "/etc/sysctl.d" ]; then
        mkdir -p "/etc/sysctl.d"
    fi
    
    if [ "$TOTAL_RAM_GB" -ge 8 ]; then
        echo "vm.swappiness=10" > "$swappiness_conf"
        log_info "Set vm.swappiness=10 (for >8GB RAM)."
    else
        echo "vm.swappiness=60" > "$swappiness_conf"
        log_info "Set vm.swappiness=60 (for <8GB RAM)."
    fi
}
