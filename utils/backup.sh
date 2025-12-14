#!/bin/bash

create_backup() {
    local target="$1"
    local backup_file="${target}.omarchy-optimizer.bkp"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [ -f "$target" ]; then
        log_header "Backing up $(basename "$target")..."
        {
            echo ""
            echo "################################################################"
            echo "# BACKUP TIMESTAMP: $timestamp"
            echo "################################################################"
            cat "$target"
        } >> "$backup_file"
    fi
}
