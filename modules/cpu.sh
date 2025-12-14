#!/bin/bash

configure_cpu() {
    log_header "Configuring CPU governor..."

    sed -i 's/#governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
    sed -i 's/governor=.*/governor="performance"/' /etc/default/cpupower 2>/dev/null
    
    if systemctl enable --now cpupower.service > /dev/null 2>&1; then
        log_info "Set governor to 'performance'."
    else
        log_warn "Could not set CPU governor. 'cpupower' service might have failed."
    fi
}
