#!/bin/bash
set -euo pipefail

# Verify OpenGrep binary signature using Cosign
# Requires: BINARY_NAME, VERSION, ACTION_PATH, ARCH, COSIGN_CACHED

install_cosign() {
    local arch="$1"

    echo "Installing cosign..."

    local cosign_binary
    case "$arch" in
        amd64)
            cosign_binary="cosign-linux-amd64"
            ;;
        arm64)
            cosign_binary="cosign-linux-arm64"
            ;;
        *)
            echo "::error::Unsupported architecture for cosign: $arch"
            return 1
            ;;
    esac

    local download_url="https://github.com/sigstore/cosign/releases/latest/download/${cosign_binary}"
    echo "Downloading cosign from: $download_url"

    if ! curl -fsSL "$download_url" -o /tmp/cosign; then
        echo "::error::Failed to download cosign"
        return 1
    fi

    chmod +x /tmp/cosign
    sudo mv /tmp/cosign /usr/local/bin/cosign

    if cosign version >/dev/null 2>&1; then
        local version_output
        version_output=$(cosign version 2>&1 | head -1)
        echo "✓ Cosign installed: $version_output"
        return 0
    else
        echo "::error::Cosign installation failed"
        return 1
    fi
}

download_signature_files() {
    local binary_name="$1"
    local version="$2"

    echo "Downloading signature files for ${binary_name}..."

    local base_url="https://github.com/opengrep/opengrep/releases/download/${version}"

    # Download signature files in parallel for performance
    curl -fsSL "${base_url}/${binary_name}.sig" -o "opengrep.sig" &
    local pid_sig=$!
    curl -fsSL "${base_url}/${binary_name}.cert" -o "opengrep.cert" &
    local pid_cert=$!

    # Wait for both downloads
    if wait $pid_sig && wait $pid_cert; then
        echo "✓ Signature files downloaded"
        return 0
    else
        echo "::error::Failed to download signature files"
        return 1
    fi
}

verify_binary_signature() {
    local binary_path="$1"

    echo "Verifying signature for opengrep binary..."

    if cosign verify-blob \
        --certificate "opengrep.cert" \
        --signature "opengrep.sig" \
        --certificate-identity-regexp "https://github.com/opengrep/opengrep.*" \
        --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
        "$binary_path"; then
        echo "✓ Binary signature verification successful!"
        return 0
    else
        echo "::error::Binary signature verification failed!"
        echo "::error::The binary may have been tampered with or is from an untrusted source"
        return 1
    fi
}

main() {
    local binary_name="${BINARY_NAME:-}"
    local version="${VERSION:-}"
    local action_path="${ACTION_PATH:-}"
    local arch="${ARCH:-}"
    local cosign_cached="${COSIGN_CACHED:-false}"

    if [ -z "$binary_name" ] || [ -z "$version" ] || [ -z "$action_path" ] || [ -z "$arch" ]; then
        echo "::error::Required environment variables missing"
        echo "::error::  BINARY_NAME: $binary_name"
        echo "::error::  VERSION: $version"
        echo "::error::  ACTION_PATH: $action_path"
        echo "::error::  ARCH: $arch"
        exit 1
    fi

    echo "::group::Verifying Binary Signature"

    cd "$action_path/bin"

    # Install cosign if not cached
    if [ "$cosign_cached" != "true" ]; then
        if ! install_cosign "$arch"; then
            exit 1
        fi
    else
        echo "✓ Using cached cosign binary"
    fi

    # Download signature files
    if ! download_signature_files "$binary_name" "$version"; then
        exit 1
    fi

    # Verify signature
    if verify_binary_signature "opengrep"; then
        # Mark as verified
        touch .verified
        echo "✓ Verification marker created"
    else
        # Clean up on failure
        rm -f opengrep .verified
        exit 1
    fi

    # Cleanup signature files
    rm -f opengrep.sig opengrep.cert
    echo "✓ Cleaned up signature files"

    echo "::endgroup::"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi
