#!/bin/bash
# Note: Not using 'set -e' to allow continuing after individual runner failures
set -o pipefail

# Check dependencies
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is not installed. Please install it first."
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  RHEL/CentOS: sudo yum install jq"
        echo "  macOS: brew install jq"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl is not installed. Please install it first."
        exit 1
    fi

    if ! command -v shasum &> /dev/null && ! command -v sha256sum &> /dev/null; then
        echo "ERROR: shasum or sha256sum is not installed."
        exit 1
    fi
}

# Validate config file exists
validate_config_file() {
    local config_file=$1

    if [ -z "$config_file" ]; then
        echo "ERROR: No config file specified"
        echo "Usage: $0 <config.json>"
        exit 1
    fi

    if [ ! -f "$config_file" ]; then
        echo "ERROR: Config file '$config_file' not found"
        exit 1
    fi

    if ! jq empty "$config_file" 2>/dev/null; then
        echo "ERROR: Invalid JSON in config file"
        exit 1
    fi
}

# Expand environment variables in string
expand_env_vars() {
    local str=$1
    eval echo "$str"
}

# Download and validate runner package
download_runner_package() {
    local version=$1
    local platform=$2
    local expected_sha256=$3
    local download_dir=$4

    local filename="actions-runner-${platform}-${version}.tar.gz"
    local download_url="https://github.com/actions/runner/releases/download/v${version}/${filename}"
    local download_path="${download_dir}/${filename}"

    # Check if already downloaded and validated
    if [ -f "$download_path" ]; then
        echo "Runner package already exists, validating..."
        if validate_sha256 "$download_path" "$expected_sha256"; then
            echo "Existing package is valid, skipping download"
            return 0
        else
            echo "Existing package invalid, re-downloading..."
            rm -f "$download_path"
        fi
    fi

    echo "Downloading runner package from ${download_url}..."
    if ! curl -o "$download_path" -L "$download_url"; then
        echo "ERROR: Failed to download runner package"
        return 1
    fi

    if ! validate_sha256 "$download_path" "$expected_sha256"; then
        echo "ERROR: SHA256 validation failed"
        rm -f "$download_path"
        return 1
    fi

    echo "Runner package downloaded and validated successfully"
    return 0
}

# Validate SHA256 checksum
validate_sha256() {
    local file=$1
    local expected_sha256=$2

    echo "Validating SHA256 checksum..."

    local actual_sha256
    if command -v shasum &> /dev/null; then
        actual_sha256=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        actual_sha256=$(sha256sum "$file" | awk '{print $1}')
    fi

    if [ "$actual_sha256" = "$expected_sha256" ]; then
        echo "SHA256 checksum valid"
        return 0
    else
        echo "ERROR: SHA256 mismatch!"
        echo "  Expected: $expected_sha256"
        echo "  Got:      $actual_sha256"
        return 1
    fi
}

# Setup a single runner instance
setup_runner_instance() {
    local runner_dir=$1
    local runner_package=$2
    local github_url=$3
    local token=$4
    local runner_group=$5
    local runner_name=$6

    echo "Setting up runner in: ${runner_dir}"

    # Create runner directory
    mkdir -p "$runner_dir"
    cd "$runner_dir"

    # Check if runner is already configured
    if [ -f ".runner" ]; then
        echo "Runner already configured, skipping configuration..."

        # Just try to start it
        echo "Starting runner..."
        if [ -f "./svc.sh" ]; then
            if sudo ./svc.sh status >/dev/null 2>&1; then
                echo "✓ Runner service already running"
                return 0
            else
                # Service exists but not running, try to start
                if sudo ./svc.sh start 2>&1 | grep -v "^$"; then
                    sleep 2
                    if sudo ./svc.sh status >/dev/null 2>&1; then
                        echo "✓ Runner service started"
                        return 0
                    fi
                fi
            fi
        fi

        # Check if running as background process
        if [ -f "runner.pid" ]; then
            local old_pid=$(cat runner.pid)
            if kill -0 "$old_pid" 2>/dev/null; then
                echo "✓ Runner already running in background (PID: $old_pid)"
                return 0
            fi
        fi

        # If we got here, runner is configured but not running, start in background
        echo "Starting runner in background mode..."
        nohup ./run.sh > "${runner_dir}/runner.log" 2>&1 &
        local pid=$!
        echo $pid > "${runner_dir}/runner.pid"
        sleep 2
        if kill -0 $pid 2>/dev/null; then
            echo "✓ Runner started in background (PID: $pid)"
            return 0
        fi
    fi

    # Extract runner package (only if not already configured)
    echo "Extracting runner package..."
    tar xzf "$runner_package" -C "$runner_dir" 2>/dev/null || true

    # Configure runner
    echo "Configuring runner..."

    local config_args=(
        "--url" "$github_url"
        "--token" "$token"
        "--name" "$runner_name"
        "--unattended"
    )

    # Add runner group if not Default
    if [ "$runner_group" != "Default" ]; then
        config_args+=("--runnergroup" "$runner_group")
    fi

    echo "Running: ./config.sh ${config_args[*]}"

    # Capture output from config.sh
    local config_output
    local config_exit_code
    config_output=$(./config.sh "${config_args[@]}" 2>&1)
    config_exit_code=$?

    # Always show the output
    echo "$config_output"

    if [ $config_exit_code -ne 0 ]; then
        echo ""
        echo "ERROR: Failed to configure runner (exit code: $config_exit_code)"
        echo "ERROR: Runner name: $runner_name"
        echo "ERROR: Directory: $runner_dir"
        return 1
    fi

    echo "Runner configured successfully"

    # Install and start the runner
    echo "Starting runner..."

    # Method 1: Try to install and start as systemd service
    if [ -f "./svc.sh" ]; then
        echo "Attempting to install as systemd service..."
        if sudo ./svc.sh install 2>&1 | grep -v "^$"; then
            if sudo ./svc.sh start 2>&1 | grep -v "^$"; then
                sleep 2
                if sudo ./svc.sh status >/dev/null 2>&1; then
                    echo "✓ Runner service started successfully"
                    return 0
                fi
            fi
        fi
        echo "Service installation failed, trying background mode..."
    fi

    # Method 2: Fallback to background process
    echo "Starting runner in background mode..."
    nohup ./run.sh > "${runner_dir}/runner.log" 2>&1 &
    local pid=$!
    echo $pid > "${runner_dir}/runner.pid"

    # Wait a moment and check if process is still running
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo "✓ Runner started in background (PID: $pid)"
        echo "  Log file: ${runner_dir}/runner.log"
        return 0
    else
        echo "ERROR: Runner process died immediately, check ${runner_dir}/runner.log"
        return 1
    fi
}

# Main function
main() {
    local config_file=$1

    echo "=== GitHub Runner Setup Script ==="
    echo

    check_dependencies
    validate_config_file "$config_file"

    # Parse runner configuration
    local runner_version=$(jq -r '.runners_config.runner_version' "$config_file")
    local runner_platform=$(jq -r '.runners_config.runner_platform' "$config_file")
    local runner_sha256=$(jq -r '.runners_config.runner_sha256' "$config_file")

    echo "Runner Configuration:"
    echo "  Version:  $runner_version"
    echo "  Platform: $runner_platform"
    echo "  SHA256:   $runner_sha256"
    echo

    # Create temporary directory for downloads
    local temp_download_dir="/tmp/github-runner-downloads"
    mkdir -p "$temp_download_dir"

    # Download runner package once
    local runner_package="${temp_download_dir}/actions-runner-${runner_platform}-${runner_version}.tar.gz"
    if ! download_runner_package "$runner_version" "$runner_platform" "$runner_sha256" "$temp_download_dir"; then
        echo "ERROR: Failed to download runner package"
        exit 1
    fi

    # Track successes and failures
    local -a failed_runners=()
    local -a successful_runners=()
    local total_runners=0

    # Process each VM configuration
    local vm_count=$(jq '.runners_config.vms | length' "$config_file")

    for ((vm_idx=0; vm_idx<vm_count; vm_idx++)); do
        local base_path=$(jq -r ".runners_config.vms[$vm_idx].base_path" "$config_file")
        local org_count=$(jq ".runners_config.vms[$vm_idx].organizations | length" "$config_file")

        echo "Processing VM $((vm_idx+1))/${vm_count}: base_path=${base_path}"

        # Create base path
        mkdir -p "$base_path"

        # Process each organization
        for ((org_idx=0; org_idx<org_count; org_idx++)); do
            local org_name=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].name" "$config_file")
            local github_url=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].github_url" "$config_file")
            local token=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].token" "$config_file")

            # Expand environment variables in token
            token=$(expand_env_vars "$token")

            echo "  Organization: ${org_name}"

            local org_path="${base_path}/${org_name}"
            mkdir -p "$org_path"

            # Process each runner group
            local group_count=$(jq ".runners_config.vms[$vm_idx].organizations[$org_idx].runner_groups | length" "$config_file")

            for ((group_idx=0; group_idx<group_count; group_idx++)); do
                local group_name=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].runner_groups[$group_idx].name" "$config_file")
                local github_name=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].runner_groups[$group_idx].github_name // empty" "$config_file")
                local instances=$(jq -r ".runners_config.vms[$vm_idx].organizations[$org_idx].runner_groups[$group_idx].instances" "$config_file")

                echo "    Runner Group: ${group_name} (${instances} instances)"

                local group_path="${org_path}/${group_name}"
                mkdir -p "$group_path"

                # Setup each runner instance
                for ((instance=1; instance<=instances; instance++)); do
                    local runner_dir="${group_path}/runner-${instance}"

                    # Use github_name if provided, otherwise use default naming
                    local runner_name
                    if [ -n "$github_name" ]; then
                        runner_name="${github_name}-${instance}"
                    else
                        runner_name="${org_name}-${group_name}-runner-${instance}"
                    fi

                    echo "      Setting up runner-${instance} (GitHub name: ${runner_name})..."
                    ((total_runners++))

                    if setup_runner_instance "$runner_dir" "$runner_package" "$github_url" "$token" "$group_name" "$runner_name"; then
                        successful_runners+=("$runner_name")
                    else
                        echo "WARNING: Failed to setup runner ${runner_name}, continuing with others..."
                        failed_runners+=("$runner_name")
                    fi
                done
            done
        done
    done

    echo
    echo "=== Setup Summary ==="
    echo "Total runners: $total_runners"
    echo "Successful: ${#successful_runners[@]}"
    echo "Failed: ${#failed_runners[@]}"
    echo

    if [ ${#failed_runners[@]} -gt 0 ]; then
        echo "Failed runners:"
        for runner in "${failed_runners[@]}"; do
            echo "  ✗ $runner"
        done
        echo
        echo "Check the error messages above for details."
        exit 1
    else
        echo "✓ All runners configured successfully!"
        echo
        echo "To start a runner, navigate to its directory and run:"
        echo "  cd <runner-directory>"
        echo "  ./run.sh"
        echo
        echo "To run a runner as a service, use:"
        echo "  cd <runner-directory>"
        echo "  sudo ./svc.sh install"
        echo "  sudo ./svc.sh start"
        exit 0
    fi
}

# Run main function
main "$@"