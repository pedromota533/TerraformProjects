#!/bin/bash

set -euo pipefail

# ============================================================================
# GitHub Actions Self-Hosted Runner Setup Script
# ============================================================================
# This script downloads, configures, and starts a GitHub Actions runner
# with proper error handling and validation
# ============================================================================

# Configuration Variables
RUNNER_VERSION="${RUNNER_VERSION:-2.329.0}"
RUNNER_ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_ARCHIVE}"
EXPECTED_HASH="194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
REPO_URL="${REPO_URL:-}"
RUNNER_TOKEN="${RUNNER_TOKEN:-}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64}"

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

cleanup_on_error() {
    rm -f "$RUNNER_DIR/$RUNNER_ARCHIVE" 2>/dev/null || true
}

trap cleanup_on_error ERR

# ============================================================================
# Validation Functions
# ============================================================================

check_required_commands() {
    local missing_commands=()

    for cmd in curl tar sha256sum; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        exit 1
    fi
}

validate_variables() {
    if [[ -z "$REPO_URL" ]]; then
        log_error "REPO_URL is not set"
        exit 1
    fi

    if [[ -z "$RUNNER_TOKEN" ]]; then
        log_error "RUNNER_TOKEN is not set"
        exit 1
    fi
}

# ============================================================================
# Installation Functions
# ============================================================================

create_runner_directory() {
    mkdir -p "$RUNNER_DIR"
    cd "$RUNNER_DIR"
    log_info "Runner directory: $RUNNER_DIR"
}

download_runner() {
    # Skip download if runner is already installed
    if [[ -f "./config.sh" ]]; then
        log_info "Runner already installed, skipping download"
        return 0
    fi

    log_info "Downloading runner v${RUNNER_VERSION}"
    rm -f "$RUNNER_ARCHIVE" 2>/dev/null || true

    if ! curl -sSL -o "$RUNNER_ARCHIVE" "$RUNNER_DOWNLOAD_URL"; then
        log_error "Download failed"
        exit 1
    fi
}

validate_hash() {
    # Skip if already installed
    if [[ -f "./config.sh" ]]; then
        return 0
    fi

    log_info "Validating hash"
    local actual_hash
    actual_hash=$(sha256sum "$RUNNER_ARCHIVE" | awk '{print $1}')

    if [[ "$actual_hash" != "$EXPECTED_HASH" ]]; then
        log_error "Hash validation failed"
        exit 1
    fi
}

extract_runner() {
    # Skip if already installed
    if [[ -f "./config.sh" ]]; then
        return 0
    fi

    log_info "Extracting"
    if ! tar xzf "./$RUNNER_ARCHIVE"; then
        log_error "Extraction failed"
        exit 1
    fi

    # Install runner dependencies
    if [[ -f "./bin/installdependencies.sh" ]]; then
        log_info "Installing runner dependencies"
        sudo ./bin/installdependencies.sh 2>/dev/null || log_warn "Dependency installation had warnings"
    fi
}

configure_runner() {
    log_info "Configuring runner: $RUNNER_NAME"

    # Stop service if running
    if [[ -f "./svc.sh" ]]; then
        sudo ./svc.sh stop 2>/dev/null || true
        sudo ./svc.sh uninstall 2>/dev/null || true
    fi

    # Always remove old configuration before reconfiguring
    log_info "Removing old configuration"
    ./config.sh remove --token "$RUNNER_TOKEN" 2>/dev/null || true

    local config_output
    if ! config_output=$(./config.sh \
        --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --unattended 2>&1); then
        log_error "Configuration failed"
        echo "$config_output" >&2
        exit 1
    fi
}

install_service() {
    log_info "Starting runner"

    # Try to install as service first
    if [[ -f "./svc.sh" ]]; then
        if sudo ./svc.sh install >/dev/null 2>&1 && sudo ./svc.sh start >/dev/null 2>&1; then
            # Check if service actually started
            sleep 2
            if sudo ./svc.sh status >/dev/null 2>&1; then
                log_info "Service started successfully"
                return 0
            else
                log_error "Service failed to start"
                sudo ./svc.sh uninstall >/dev/null 2>&1 || true
                return 1
            fi
        fi
    fi

    # Fallback: run as background process
    log_info "Starting runner in background"
    nohup ./run.sh > /tmp/runner.log 2>&1 &
    echo $! > /tmp/runner.pid
    log_info "Runner started (PID: $(cat /tmp/runner.pid))"
}

do_full_reinstall() {
    log_info "Performing full reinstall"

    # Stop and remove service if exists
    if [[ -f "$RUNNER_DIR/svc.sh" ]]; then
        cd "$RUNNER_DIR"
        sudo ./svc.sh stop 2>/dev/null || true
        sudo ./svc.sh uninstall 2>/dev/null || true
    fi

    # Remove entire directory
    rm -rf "$RUNNER_DIR"

    # Recreate and install from scratch
    create_runner_directory
    download_runner
    validate_hash
    extract_runner
    configure_runner
    cleanup_archive
    install_service
}

start_runner_interactive() {
    log_info "Starting runner in interactive mode..."
    log_warn "Press Ctrl+C to stop the runner"

    if [[ ! -x "./run.sh" ]]; then
        log_error "run.sh is not executable"
        exit 1
    fi

    ./run.sh
}

cleanup_archive() {
    rm -f "$RUNNER_ARCHIVE" 2>/dev/null || true
}

# ============================================================================
# Main Execution
# ============================================================================

check_runner_status() {
    # Check if runner directory exists
    if [[ ! -d "$RUNNER_DIR" ]]; then
        log_info "Runner not installed"
        return 1
    fi

    cd "$RUNNER_DIR"

    # Check if runner is configured
    if [[ ! -f "./.runner" ]]; then
        log_info "Runner not configured"
        return 1
    fi

    # Check if service exists and is running
    if [[ -f "./svc.sh" ]]; then
        if sudo ./svc.sh status >/dev/null 2>&1; then
            log_info "Runner service is running - skipping installation"
            return 0
        else
            log_warn "Runner service exists but not running"
            return 1
        fi
    fi

    # Check if background process is running
    if [[ -f "/tmp/runner.pid" ]]; then
        local pid=$(cat /tmp/runner.pid)
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Runner background process is running (PID: $pid) - skipping installation"
            return 0
        else
            log_warn "Runner process not running (stale PID file)"
            return 1
        fi
    fi

    log_warn "Runner installed but not running"
    return 1
}

main() {
    log_info "GitHub Actions Runner Setup Started"

    check_required_commands
    validate_variables

    # Check if runner is already working
    if check_runner_status; then
        log_info "Runner is healthy - nothing to do"
        exit 0
    fi

    # Runner is broken or not installed, proceed with installation
    log_info "Runner needs installation/repair"

    create_runner_directory
    download_runner
    validate_hash
    extract_runner
    configure_runner
    cleanup_archive

    # Try to install service
    if ! install_service; then
        # Service failed, do full reinstall
        log_warn "Service failed, attempting full reinstall"
        do_full_reinstall
    fi

    log_info "Setup Complete - Runner installed and running"
}

# Run main function
main "$@"
