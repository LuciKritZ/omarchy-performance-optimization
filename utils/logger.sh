#!/bin/bash

# Color Definitions
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color

# Logging Functions
log_header() {
    echo -e "${BLUE}:: $1${NC}"
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_info() {
    echo -e "   $1"
}

log_warn() {
    echo -e "${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}Error: $1${NC}"
}
