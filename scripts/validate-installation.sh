#!/bin/bash
set -euo pipefail

# Validate OpenGrep binary installation
# Checks file existence, permissions, and basic functionality

validate_installation() {
    local binary_path="$1"

    echo "Validating OpenGrep installation at: $binary_path"

    # Check if file exists
    if [ ! -f "$binary_path" ]; then
        echo "::error::OpenGrep binary not found at $binary_path"
        echo "::error::Installation may have failed or binary was removed"
        return 1
    fi

    # Check if executable
    if [ ! -x "$binary_path" ]; then
        echo "::error::OpenGrep binary is not executable: $binary_path"
        echo "::error::Permissions may be incorrect"
        ls -l "$binary_path"
        return 1
    fi

    # Verify functionality
    if ! "$binary_path" --version >/dev/null 2>&1; then
        echo "::error::OpenGrep binary exists but is not functional"
        echo "::error::Binary may be corrupted or incompatible"
        return 1
    fi

    # Get and display version
    local version_output
    version_output=$("$binary_path" --version 2>&1 | head -1)
    echo "✓ OpenGrep installed and functional: $version_output"

    return 0
}

# Main execution
main() {
    local binary_path="${BINARY_PATH:-}"

    if [ -z "$binary_path" ]; then
        echo "::error::BINARY_PATH environment variable not set"
        exit 1
    fi

    if ! validate_installation "$binary_path"; then
        exit 1
    fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi
