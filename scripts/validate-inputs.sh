#!/bin/bash
set -euo pipefail

# Input validation script for OpenGrep Action
# Validates all user inputs to prevent injection and ensure correctness

validate_version() {
    local version="$1"

    # Version must match vX.Y.Z format
    if ! [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "::error::Invalid version format: $version (expected format: vX.Y.Z, e.g., v1.10.2)"
        return 1
    fi

    echo "✓ Version format valid: $version"
    return 0
}

validate_output_format() {
    local format="$1"

    case "$format" in
        json|sarif|text|gitlab-sast|gitlab-secrets|junit-xml|semgrep-json)
            echo "✓ Output format valid: $format"
            return 0
            ;;
        *)
            echo "::error::Invalid output format: $format"
            echo "::error::Supported formats: json, sarif, text, gitlab-sast, gitlab-secrets, junit-xml, semgrep-json"
            return 1
            ;;
    esac
}

validate_severity() {
    local severity="$1"

    case "$severity" in
        INFO|WARNING|ERROR)
            echo "✓ Severity valid: $severity"
            return 0
            ;;
        *)
            echo "::error::Invalid severity: $severity (must be INFO, WARNING, or ERROR)"
            return 1
            ;;
    esac
}

validate_numeric() {
    local name="$1"
    local value="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "::error::Invalid $name: $value (must be a positive integer)"
        return 1
    fi

    echo "✓ $name valid: $value"
    return 0
}

validate_boolean() {
    local name="$1"
    local value="$2"

    case "$value" in
        true|false)
            echo "✓ $name valid: $value"
            return 0
            ;;
        *)
            echo "::error::Invalid $name: $value (must be 'true' or 'false')"
            return 1
            ;;
    esac
}

validate_paths() {
    local paths="$1"

    # Check for dangerous shell metacharacters
    if [[ "$paths" =~ [\;\$\`] ]]; then
        echo "::error::Paths contain dangerous characters (;, \$, or backtick)"
        return 1
    fi

    echo "✓ Paths format valid: $paths"
    return 0
}

validate_file_path() {
    local path="$1"

    # Check for path traversal attempts
    if [[ "$path" =~ \.\. ]]; then
        echo "::warning::Output file path contains '..': $path"
    fi

    # Check for absolute paths outside workspace (if not absolute, it's relative and safe)
    if [[ "$path" == /* ]] && [[ ! "$path" =~ ^/workspaces/ ]] && [[ ! "$path" =~ ^/home/runner/ ]]; then
        echo "::warning::Output file path is absolute outside workspace: $path"
    fi

    echo "✓ File path format valid: $path"
    return 0
}

# Main validation
main() {
    local exit_code=0

    echo "::group::Validating Inputs"

    # Validate core inputs
    validate_version "${INPUT_VERSION:-}" || exit_code=1
    validate_output_format "${INPUT_OUTPUT_FORMAT:-}" || exit_code=1
    validate_severity "${INPUT_SEVERITY:-}" || exit_code=1
    validate_numeric "max-target-bytes" "${INPUT_MAX_TARGET_BYTES:-}" || exit_code=1
    validate_numeric "timeout" "${INPUT_TIMEOUT:-}" || exit_code=1
    validate_boolean "verify-signature" "${INPUT_VERIFY_SIGNATURE:-}" || exit_code=1
    validate_boolean "fail-on-findings" "${INPUT_FAIL_ON_FINDINGS:-}" || exit_code=1
    validate_boolean "upload-artifacts" "${INPUT_UPLOAD_ARTIFACTS:-}" || exit_code=1
    validate_paths "${INPUT_PATHS:-}" || exit_code=1
    validate_file_path "${INPUT_OUTPUT_FILE:-}" || exit_code=1

    # Validate optional performance inputs
    if [ -n "${INPUT_JOBS:-}" ]; then
        validate_numeric "jobs" "${INPUT_JOBS}" || exit_code=1
    fi

    if [ -n "${INPUT_MAX_MEMORY:-}" ]; then
        validate_numeric "max-memory" "${INPUT_MAX_MEMORY}" || exit_code=1
    fi

    # Validate optional boolean inputs
    if [ -n "${INPUT_ENABLE_METRICS:-}" ]; then
        validate_boolean "enable-metrics" "${INPUT_ENABLE_METRICS}" || exit_code=1
    fi

    if [ -n "${INPUT_VERBOSE:-}" ]; then
        validate_boolean "verbose" "${INPUT_VERBOSE}" || exit_code=1
    fi

    if [ -n "${INPUT_NO_GIT_IGNORE:-}" ]; then
        validate_boolean "no-git-ignore" "${INPUT_NO_GIT_IGNORE}" || exit_code=1
    fi

    echo "::endgroup::"

    if [ $exit_code -eq 0 ]; then
        echo "::notice::All inputs validated successfully"
    else
        echo "::error::Input validation failed"
    fi

    return $exit_code
}

# Run validation if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi
