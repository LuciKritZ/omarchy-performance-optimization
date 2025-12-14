#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/constants.sh"

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Restoration Utility initialized"

restore_file() {
    local target="$1"
    local backup="${target}.omarchy-optimizer.bkp"
    
    echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
    log_warn "Target: $target"
    
    if [ ! -f "$backup" ]; then
        log_error "No backup history found for this file."
        return
    fi

    mapfile -t TIMESTAMPS < <(grep -n "# BACKUP TIMESTAMP:" "$backup")
    
    if [ ${#TIMESTAMPS[@]} -eq 0 ]; then
        log_error "Backup file is empty or malformed."
        return
    fi

    while true; do
        log_header "Available Restore Points:"
        local count=0
        declare -A LINE_MAP

        # Display Options (Repaint list every loop)
        for entry in "${TIMESTAMPS[@]}"; do
            count=$((count + 1))
            local line_num="${entry%%:*}"
            local label="${entry#*:}" 
            label="${label#*TIMESTAMP: }"
            
            log_info "[${count}] $label"
            LINE_MAP[$count]=$line_num
        done

        log_info "[0] Skip this file"
        echo ""
        read -p "Select a version [0-$count]: " choice

        # Handle Skip
        if [[ "$choice" -eq 0 || -z "$choice" ]]; then
            echo "Skipping."
            return
        fi

        # Validate Input
        if [[ -z "${LINE_MAP[$choice]}" ]]; then
            log_error "Invalid selection."
            continue
        fi

        local start_line="${LINE_MAP[$choice]}"
        local content_start=$((start_line + 2))
        local next_index=$((choice + 1))
        local end_line=""

        if [[ -n "${LINE_MAP[$next_index]}" ]]; then
            local next_start="${LINE_MAP[$next_index]}"
            end_line=$((next_start - 3))
        else
            end_line="$"
        fi

        echo -e "\n${GREEN}--- PREVIEW START ---${NC}"
        sed -n "${content_start},${end_line}p" "$backup"
        echo -e "${GREEN}--- PREVIEW END ---${NC}\n"

        read -p "Do you want to restore this version? [y/N] " confirm_restore

        if [[ "$confirm_restore" =~ ^[Yy]$ ]]; then
            log_success "Restoring version..."
            sed -n "${content_start},${end_line}p" "$backup" > "$target"
            log_success "✔ Restored $target"
            break # Exit loop for this loop
        else
            log_info "Not restored. You can select another version."
            # Loop continues, re-displaying the list
        fi
    done
}

for file in "${RESTORE_TARGETS[@]}"; do
    restore_file "$file"
done

echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
log_warn "Package Cleanup Advice"
log_info "The optimizer may have installed specific drivers. Below are the packages"
log_info "currently installed on your system that match our management list."
log_info "Please review and uninstall any you no longer need manually."
log_header "(Command: pacman -Rns <package_name>)\n"

FOUND_PKGS=0
for pkg in "${MANAGED_PACKAGES[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "    • ${GREEN}$pkg${NC} (Installed)"
        FOUND_PKGS=1
    fi
done

if [ $FOUND_PKGS -eq 0 ]; then
    log_info "(No managed packages detected)"
fi

echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
read -p "Do you want to rebuild system images (initramfs/bootloader) now? [Y/n] " confirm
if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
    log_header "Running limine-mkinitcpio..."
    
    pacman -S --noconfirm linux > /dev/null 2>&1
    
    if limine-mkinitcpio; then
        log_success ":: Rebuild Successful."
        log_warn ":: Please reboot your system."
    else
        log_error ":: Rebuild Failed."
    fi
else
    log_info "Skipping rebuild."
    log_info "Remember to run 'sudo limine-mkinitcpio' manually if you changed configs."
fi
