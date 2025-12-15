#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/constants.sh"
source "$SCRIPT_DIR/utils/restore.sh"

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Restoration Utility initialized"

restore_interactive() {
    local target="$1"
    local backup="${target}.omarchy-optimizer.bkp"
    
    echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
    log_warn "Target: $target"
    
    get_backup_timestamps "$backup"
    
    if [ ${#parsed_timestamps[@]} -eq 0 ]; then
        log_error "No backup history found."
        return
    fi

    while true; do
        log_header "Available Restore Points:"
        local count=0
        declare -A LINE_MAP

        for entry in "${parsed_timestamps[@]}"; do
            count=$((count + 1))
            local line_num="${entry%%:*}"
            local label="${entry#*:}" 
            label="${label#*TIMESTAMP: }"
            
            log_info "[${count}] $label"
            LINE_MAP[$count]=$line_num
        done

        log_info "[0] Skip this file"
        echo ""
        read -p "Select a version to preview [0-$count]: " choice

        if [[ "$choice" -eq 0 || -z "$choice" ]]; then
            log_info "Skipping."
            return
        fi

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
            apply_restore "$backup" "$target" "$content_start" "$end_line"
            break
        fi
    done
}

for file in "${RESTORE_TARGETS[@]}"; do
    restore_interactive "$file"
done

show_cleanup_advice

echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
read -p "Do you want to rebuild system images now? [Y/n] " confirm_build
if [[ "$confirm_build" =~ ^[Yy]$ || -z "$confirm_build" ]]; then
    run_rebuild
else
    log_info "Skipping rebuild. Run 'sudo limine-mkinitcpio' manually."
fi
