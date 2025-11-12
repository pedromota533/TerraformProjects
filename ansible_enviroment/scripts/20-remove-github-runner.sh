#!/bin/bash

set -euo pipefail

# ============================================================================
# GitHub Actions Runner Removal Script (Conditional)
# ============================================================================
# Only runs if REMOVE_RUNNER=true is set
# ============================================================================

RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
RUNNER_TOKEN="${RUNNER_TOKEN:-}"
REMOVE_RUNNER="${REMOVE_RUNNER:-false}"

# ============================================================================
# Utility Functions
# ============================================================================

log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# ============================================================================
# Main Functions
# ============================================================================

check_if_removal_requested() {
    if [[ "$REMOVE_RUNNER" != "true" ]]; then
        log_info "Runner removal not requested (set REMOVE_RUNNER=true to remove)"
        exit 0
    fi
}

validate_token() {
    if [[ -z "$RUNNER_TOKEN" ]]; then
        log_error "RUNNER_TOKEN is not set"
        exit 1
    fi
}

remove_runner() {
    log_info "GitHub Actions Runner Removal Started"

    # Check if runner directory exists
    if [[ ! -d "$RUNNER_DIR" ]]; then
        log_warn "Runner directory not found: $RUNNER_DIR"
        log_info "Nothing to remove"
        exit 0
    fi

    cd "$RUNNER_DIR"

    # Stop and uninstall service if exists
    if [[ -f "./svc.sh" ]]; then
        log_info "Stopping runner service"
        sudo ./svc.sh stop 2>/dev/null || log_warn "Service stop failed or not running"

        log_info "Uninstalling runner service"
        sudo ./svc.sh uninstall 2>/dev/null || log_warn "Service uninstall failed or not installed"
    fi

    # Kill background runner process if exists
    if [[ -f "/tmp/runner.pid" ]]; then
        log_info "Stopping background runner process"
        local pid=$(cat /tmp/runner.pid)
        if kill "$pid" 2>/dev/null; then
            log_info "Stopped runner process (PID: $pid)"
        fi
        rm -f /tmp/runner.pid
    fi

    # Remove runner configuration
    if [[ -f "./config.sh" ]]; then
        log_info "Removing runner configuration"
        if ./config.sh remove --token "$RUNNER_TOKEN" 2>/dev/null; then
            log_info "Runner configuration removed successfully"
        else
            log_warn "Failed to remove runner configuration (may not be registered)"
        fi
    else
        log_warn "config.sh not found, skipping configuration removal"
    fi

    # Remove runner directory
    log_info "Removing runner directory: $RUNNER_DIR"
    cd /tmp
    rm -rf "$RUNNER_DIR"

    log_info "Runner removal complete"
}

# ============================================================================
# Main Execution
# ============================================================================

check_if_removal_requested
validate_token
remove_runner
