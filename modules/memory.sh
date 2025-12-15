#!/bin/bash

configure_memory() {
    log_header "Configuring memory performance..."

    if [ "$TOTAL_RAM_GB" -ge 8 ]; then
        export MEMORY_KERNEL_ARGS="zswap.enabled=1 zswap.compressor=lz4 zswap.zpool=z3fold zswap.max_pool_percent=25"
    else
        export MEMORY_KERNEL_ARGS="zswap.enabled=1 zswap.compressor=zstd zswap.zpool=z3fold zswap.max_pool_percent=20"
    fi
    log_info "Generated Zswap kernel arguments."

    local sysctl_dir=$(dirname "$SYSCTL_RAM_CONF")

    if [ ! -d "$sysctl_dir" ]; then
        mkdir -p "$sysctl_dir"
    fi
    
    if [ "$TOTAL_RAM_GB" -ge 8 ]; then
        echo "vm.swappiness=10" > "$SYSCTL_RAM_CONF"
        log_info "Set vm.swappiness=10 (for >8GB RAM)."
    else
        echo "vm.swappiness=60" > "$SYSCTL_RAM_CONF"
        log_info "Set vm.swappiness=60 (for <8GB RAM)."
    fi
}
