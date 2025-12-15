#!/bin/bash

# Parse a backup file and return an array of "LineNumber:TimestampString"
# Usage: get_backup_timestamps "/path/to/backup_file"
# Returns: Sets the global array parsed_timestamps
get_backup_timestamps() {
    local backup_file="$1"
    parsed_timestamps=()
    
    if [ ! -f "$backup_file" ]; then
        return 1
    fi

    # Read grep output into array
    mapfile -t parsed_timestamps < <(grep -n "# BACKUP TIMESTAMP:" "$backup_file")
}

# Perform the actual file overwrite
# Usage: apply_restore "backup_file" "target_file" "start_line" "end_line"
apply_restore() {
    local backup="$1"
    local target="$2"
    local start="$3"
    local end="$4"

    log_info "Restoring content from lines $start to $end..."
    sed -n "${start},${end}p" "$backup" > "$target"
    log_success "✔ Restored $target"
}

# Check for managed packages and print advice
show_cleanup_advice() {
    echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
    log_warn "Package Cleanup Advice"
    log_info "The following packages managed by the optimizer are currently installed."
    log_info "If you are rolling back, you may want to uninstall them manually."
    log_header "(Command: pacman -Rns <package_name>)\n"

    local found_pkgs=0
    for pkg in "${MANAGED_PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &> /dev/null; then
            echo -e "   • ${GREEN}$pkg${NC} (Installed)"
            found_pkgs=1
        fi
    done

    if [ $found_pkgs -eq 0 ]; then
        log_info "(No managed packages detected)"
    fi
}

# Run the system image rebuild
run_rebuild() {
    log_header "Running limine-mkinitcpio..."
    
    # Sync headers first
    pacman -S --noconfirm linux > /dev/null 2>&1
    
    if limine-mkinitcpio; then
        log_success ":: Rebuild Successful."
        log_warn ":: Please reboot your system."
    else
        log_error ":: Rebuild Failed."
    fi
}
