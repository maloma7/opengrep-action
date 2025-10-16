#!/bin/bash
set -euo pipefail

# Download OpenGrep binary with retry logic and basic validation
# Requires: BINARY_NAME, VERSION, ACTION_PATH

download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if curl -fsSL "$url" -o "$output"; then
            echo "✓ Download successful"
            return 0
        fi

        retry_count=$((retry_count + 1))

        if [ $retry_count -lt $max_retries ]; then
            local wait_time=$((2 ** retry_count))
            echo "::warning::Download failed, retrying in ${wait_time}s... (attempt $((retry_count + 1))/$max_retries)"
            sleep $wait_time
        fi
    done

    echo "::error::Failed to download after $max_retries attempts"
    return 1
}

main() {
    local binary_name="${BINARY_NAME:-}"
    local version="${VERSION:-}"
    local action_path="${ACTION_PATH:-}"

    if [ -z "$binary_name" ] || [ -z "$version" ] || [ -z "$action_path" ]; then
        echo "::error::Required environment variables missing"
        echo "::error::  BINARY_NAME: $binary_name"
        echo "::error::  VERSION: $version"
        echo "::error::  ACTION_PATH: $action_path"
        exit 1
    fi

    echo "::group::Downloading OpenGrep $version"

    # Create bin directory
    mkdir -p "$action_path/bin"
    cd "$action_path/bin"

    # Construct download URL
    local download_url="https://github.com/opengrep/opengrep/releases/download/${version}/${binary_name}"
    echo "Downloading from: $download_url"

    # Download with retry
    if ! download_with_retry "$download_url" "opengrep"; then
        exit 1
    fi

    # Make executable
    chmod +x opengrep

    # Verify basic functionality
    echo "Verifying binary functionality..."
    if ! ./opengrep --version >/dev/null 2>&1; then
        echo "::error::Downloaded binary is not functional"
        echo "::error::Binary may be corrupted or incompatible with this system"
        exit 1
    fi

    local version_output
    version_output=$(./opengrep --version 2>&1 | head -1)
    echo "✓ Binary is functional: $version_output"

    echo "::endgroup::"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi
