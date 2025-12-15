#!/bin/bash

configure_cpu() {
    log_header "Configuring CPU governor..."

    if [ -f "$CPUPOWER_CONF" ]; then
        create_backup "$CPUPOWER_CONF"

        sed -i 's/#governor=.*/governor="performance"/' "$CPUPOWER_CONF" 2>/dev/null
        sed -i 's/governor=.*/governor="performance"/' "$CPUPOWER_CONF" 2>/dev/null
    fi
    
    if systemctl enable --now cpupower.service > /dev/null 2>&1; then
        log_info "Set governor to 'performance'."
    else
        log_warn "Could not set CPU governor. 'cpupower' service might have failed."
    fi
}
