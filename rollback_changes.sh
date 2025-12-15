#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/logger.sh"
source "$SCRIPT_DIR/utils/constants.sh"
source "$SCRIPT_DIR/utils/restore.sh"

if [[ $EUID -ne 0 ]]; then
   log_error "Must run as root."
   exit 1
fi

log_header "Omarchy Rollback Utility (Auto-Restore)"
log_warn "This script will overwrite current configs with the LATEST backup available."

for target in "${RESTORE_TARGETS[@]}"; do
    backup="${target}.omarchy-optimizer.bkp"
    
    echo -e "\n${YELLOW}Target: $target${NC}"
    
    if [ ! -f "$backup" ]; then
        log_error "No backup history found. Skipping."
        continue
    fi

    get_backup_timestamps "$backup"
    
    if [ ${#parsed_timestamps[@]} -eq 0 ]; then
        log_error "Backup file empty."
        continue
    fi

    last_entry="${parsed_timestamps[-1]}"
    
    line_num="${last_entry%%:*}"
    label="${last_entry#*:}"
    label="${label#*TIMESTAMP: }"

    start_line=$((line_num + 2))
    end_line="$"

    log_info "Latest Backup: $label"
    apply_restore "$backup" "$target" "$start_line" "$end_line"
done

show_cleanup_advice

echo -e "\n${YELLOW}------------------------------------------------------------${NC}"
log_warn "Configuration rollback complete."
read -p "Do you want to rebuild system images now? [Y/n] " confirm
if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
    run_rebuild
else
    log_info "Skipping rebuild. Run 'sudo limine-mkinitcpio' manually."
fi
