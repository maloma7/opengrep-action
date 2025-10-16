#!/bin/bash
set -euo pipefail

# Platform and architecture detection for OpenGrep binary selection
# Sets GITHUB_OUTPUT variables: binary-name and arch

detect_platform() {
    local runner_arch="$1"

    case "$runner_arch" in
        X64)
            echo "binary-name=opengrep_manylinux_x86" >> "$GITHUB_OUTPUT"
            echo "arch=amd64" >> "$GITHUB_OUTPUT"
            echo "✓ Detected platform: Linux x86_64"
            ;;
        ARM64)
            echo "binary-name=opengrep_manylinux_aarch64" >> "$GITHUB_OUTPUT"
            echo "arch=arm64" >> "$GITHUB_OUTPUT"
            echo "✓ Detected platform: Linux ARM64"
            ;;
        *)
            echo "::error::Unsupported architecture: $runner_arch"
            echo "::error::Supported architectures: X64, ARM64"
            return 1
            ;;
    esac

    return 0
}

# Main execution
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <runner_arch>"
        exit 1
    fi

    detect_platform "$1"
fi
