#!/bin/bash
set -euo pipefail

# OpenGrep scan execution script with array-based command building
# This replaces the eval-based approach for better security and reliability

# Initialize command array
declare -a cmd_array
cmd_array=("${OPENGREP_BINARY}" "scan")

# Configuration
if [ "${INPUT_CONFIG}" != "auto" ]; then
    # Use --config for both auto and custom configs (standardized)
    cmd_array+=("--config" "${INPUT_CONFIG}")
else
    cmd_array+=("--config" "auto")
fi

# Output format and file
case "${INPUT_OUTPUT_FORMAT}" in
    json)
        cmd_array+=("--json")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    sarif)
        cmd_array+=("--sarif")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    text)
        cmd_array+=("--text")
        if [ -n "${INPUT_OUTPUT_FILE}" ]; then
            cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        fi
        ;;
    gitlab-sast)
        cmd_array+=("--gitlab-sast")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    gitlab-secrets)
        cmd_array+=("--gitlab-secrets")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    junit-xml)
        cmd_array+=("--junit-xml")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    semgrep-json)
        cmd_array+=("--semgrep-json")
        cmd_array+=("--output" "${INPUT_OUTPUT_FILE}")
        ;;
    *)
        echo "::error::Unsupported output format: ${INPUT_OUTPUT_FORMAT}"
        exit 1
        ;;
esac

# Severity filtering - use single flag (OpenGrep includes higher severities)
if [ "${INPUT_SEVERITY}" != "INFO" ]; then
    cmd_array+=("--severity" "${INPUT_SEVERITY}")
fi

# Add exclusions (properly handle arrays)
if [ -n "${INPUT_EXCLUDE:-}" ]; then
    IFS=' ' read -ra EXCLUDE_PATTERNS <<< "${INPUT_EXCLUDE}"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [ -n "$pattern" ]; then
            cmd_array+=("--exclude" "$pattern")
        fi
    done
fi

# Add inclusions
if [ -n "${INPUT_INCLUDE:-}" ]; then
    IFS=' ' read -ra INCLUDE_PATTERNS <<< "${INPUT_INCLUDE}"
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        if [ -n "$pattern" ]; then
            cmd_array+=("--include" "$pattern")
        fi
    done
fi

# Performance options
if [ -n "${INPUT_JOBS:-}" ] && [ "${INPUT_JOBS}" != "0" ]; then
    cmd_array+=("-j" "${INPUT_JOBS}")
fi

if [ -n "${INPUT_MAX_MEMORY:-}" ] && [ "${INPUT_MAX_MEMORY}" != "0" ]; then
    cmd_array+=("--max-memory" "${INPUT_MAX_MEMORY}")
fi

# Git-aware scanning
if [ -n "${INPUT_BASELINE_COMMIT:-}" ]; then
    cmd_array+=("--baseline-commit" "${INPUT_BASELINE_COMMIT}")
    echo "::notice::Performing differential scan against baseline: ${INPUT_BASELINE_COMMIT}"
fi

# Advanced options
if [ "${INPUT_ENABLE_METRICS:-false}" = "true" ]; then
    cmd_array+=("--metrics")
fi

if [ "${INPUT_VERBOSE:-false}" = "true" ]; then
    cmd_array+=("--verbose")
fi

if [ "${INPUT_NO_GIT_IGNORE:-false}" = "true" ]; then
    cmd_array+=("--no-git-ignore")
fi

# Resource limits
cmd_array+=("--max-target-bytes" "${INPUT_MAX_TARGET_BYTES}")
cmd_array+=("--timeout" "${INPUT_TIMEOUT}")

# Add scan paths at the end
IFS=' ' read -ra SCAN_PATHS <<< "${INPUT_PATHS}"
for path in "${SCAN_PATHS[@]}"; do
    if [ -n "$path" ]; then
        cmd_array+=("$path")
    fi
done

# Display command for debugging
echo "::group::OpenGrep Command"
echo "Running OpenGrep with the following command:"
printf '%q ' "${cmd_array[@]}"
echo ""
echo "::endgroup::"

# Validate binary accessibility before running
if ! "${OPENGREP_BINARY}" --version >/dev/null 2>&1; then
    echo "::error::OpenGrep binary is not functional"
    exit 1
fi

# Execute scan (no eval needed - direct array execution)
echo "::group::Running OpenGrep Scan"

set +e
"${cmd_array[@]}"
scan_exit_code=$?
set -e

echo "::endgroup::"

# Enhanced error handling based on exit codes
# Exit code 0 = no findings (success)
# Exit code 1 = findings detected (still a successful scan)
# Exit code 2+ = actual errors
case $scan_exit_code in
    0)
        echo "::notice::Scan completed successfully with no findings"
        ;;
    1)
        echo "::notice::Scan completed with findings detected"
        ;;
    2)
        echo "::error::OpenGrep scan failed due to invalid command line arguments or configuration"
        echo "::error::Please check your inputs:"
        echo "::error::  - config: ${INPUT_CONFIG}"
        echo "::error::  - paths: ${INPUT_PATHS}"
        echo "::error::  - output-format: ${INPUT_OUTPUT_FORMAT}"
        echo "::error::See detailed error messages above"
        exit 2
        ;;
    3)
        echo "::error::OpenGrep scan timed out after ${INPUT_TIMEOUT} seconds"
        echo "::error::Consider:"
        echo "::error::  - Increasing timeout value"
        echo "::error::  - Reducing scan scope with exclude patterns"
        echo "::error::  - Scanning specific directories instead of entire repository"
        exit 3
        ;;
    *)
        echo "::error::OpenGrep scan failed with unexpected exit code: $scan_exit_code"
        echo "::error::This may indicate:"
        echo "::error::  - Binary corruption or incompatibility"
        echo "::error::  - System resource exhaustion"
        echo "::error::  - OpenGrep internal error"
        exit $scan_exit_code
        ;;
esac

# Verify output file exists
if [ ! -f "${INPUT_OUTPUT_FILE}" ]; then
    echo "::warning::Expected output file not found: ${INPUT_OUTPUT_FILE}"
    echo "::warning::Creating empty output file for compatibility"

    # Create appropriate empty file based on format
    case "${INPUT_OUTPUT_FORMAT}" in
        json|semgrep-json)
            echo '{"results": []}' > "${INPUT_OUTPUT_FILE}"
            ;;
        sarif)
            echo '{"version": "2.1.0", "runs": []}' > "${INPUT_OUTPUT_FILE}"
            ;;
        *)
            touch "${INPUT_OUTPUT_FILE}"
            ;;
    esac
fi

# Export exit code for caller (for debugging and workflow logic)
echo "SCAN_EXIT_CODE=$scan_exit_code" >> "$GITHUB_OUTPUT"

# Exit with 0 for successful scans (with or without findings)
# Only exit non-zero for actual errors (exit codes 2+)
# The fail-on-findings logic in action.yml will handle whether findings should fail the workflow
if [ $scan_exit_code -le 1 ]; then
    exit 0
else
    exit $scan_exit_code
fi
