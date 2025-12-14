#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh";
source "$SCRIPT_DIR/utils/constants.sh";

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Hardware Optimizer initialized"

if [ -f "$SCRIPT_DIR/modules/detect_hardware.sh" ] && [ -f "$SCRIPT_DIR/modules/helpers.sh" ]; then
    source "$SCRIPT_DIR/modules/detect_hardware.sh"
    source "$SCRIPT_DIR/modules/helpers.sh"
else
    log_error "Missing modules in '$SCRIPT_DIR/modules/'."
    exit 1
fi

install_packages "$INSTALL_PACKAGES"
configure_limine "$KERNEL_ARGS"
configure_mkinitcpio "$MKINIT_MODULES"
finalize_system
