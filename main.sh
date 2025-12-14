#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/constants.sh"
source "$SCRIPT_DIR/utils/backup.sh"
source "$SCRIPT_DIR/modules/detect_hardware.sh"
source "$SCRIPT_DIR/modules/packages.sh"
source "$SCRIPT_DIR/modules/cpu.sh"
source "$SCRIPT_DIR/modules/bootloader.sh"

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Hardware Optimizer initialized"

detect_hardware
resolve_and_install_packages
configure_cpu
configure_bootloader
build_images
