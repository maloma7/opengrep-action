#!/bin/bash
set -euo pipefail

# Process OpenGrep scan results and count findings
# Provides fallback mechanisms when jq is not available

count_json_findings() {
    local file="$1"

    if command -v jq >/dev/null 2>&1; then
        # Use jq if available
        local findings
        local critical

        findings=$(jq '.results | length' "$file" 2>/dev/null || echo "0")
        critical=$(jq '[.results[] | select(.extra.severity == "ERROR" or .extra.severity == "CRITICAL" or .extra.severity == "HIGH")] | length' "$file" 2>/dev/null || echo "0")

        echo "FINDINGS_COUNT=$findings"
        echo "CRITICAL_COUNT=$critical"
    elif command -v python3 >/dev/null 2>&1; then
        # Fallback to Python
        python3 - "$file" <<'PYTHON'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)

    results = data.get('results', [])
    findings = len(results)

    critical = sum(1 for r in results
                   if r.get('extra', {}).get('severity') in ['ERROR', 'CRITICAL', 'HIGH'])

    print(f"FINDINGS_COUNT={findings}")
    print(f"CRITICAL_COUNT={critical}")
except Exception as e:
    print(f"FINDINGS_COUNT=0", file=sys.stderr)
    print(f"CRITICAL_COUNT=0", file=sys.stderr)
    print(f"Error parsing JSON: {e}", file=sys.stderr)
    sys.exit(0)  # Don't fail the action
PYTHON
    else
        # No JSON parser available
        echo "::warning::Neither jq nor python3 available for counting findings"
        echo "FINDINGS_COUNT=unknown"
        echo "CRITICAL_COUNT=unknown"
    fi
}

count_sarif_findings() {
    local file="$1"

    if command -v jq >/dev/null 2>&1; then
        local findings
        local critical

        # SARIF structure: .runs[].results[]
        findings=$(jq '[.runs[]?.results[]?] | length' "$file" 2>/dev/null || echo "0")
        critical=$(jq '[.runs[]?.results[]? | select(.level == "error" or .level == "warning")] | length' "$file" 2>/dev/null || echo "0")

        echo "FINDINGS_COUNT=$findings"
        echo "CRITICAL_COUNT=$critical"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PYTHON'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)

    runs = data.get('runs', [])
    all_results = []
    for run in runs:
        all_results.extend(run.get('results', []))

    findings = len(all_results)
    critical = sum(1 for r in all_results
                   if r.get('level') in ['error', 'warning'])

    print(f"FINDINGS_COUNT={findings}")
    print(f"CRITICAL_COUNT={critical}")
except Exception as e:
    print(f"FINDINGS_COUNT=0", file=sys.stderr)
    print(f"CRITICAL_COUNT=0", file=sys.stderr)
    print(f"Error parsing SARIF: {e}", file=sys.stderr)
    sys.exit(0)
PYTHON
    else
        echo "::warning::Neither jq nor python3 available for counting SARIF findings"
        echo "FINDINGS_COUNT=unknown"
        echo "CRITICAL_COUNT=unknown"
    fi
}

count_text_findings() {
    local file="$1"

    # For text format, count lines with findings (heuristic)
    # This is approximate as text format varies
    if [ -f "$file" ]; then
        local line_count
        line_count=$(wc -l < "$file" 2>/dev/null || echo "0")

        echo "::notice::Text format finding count not available (file has $line_count lines)"
        echo "FINDINGS_COUNT=unknown"
        echo "CRITICAL_COUNT=unknown"
    else
        echo "FINDINGS_COUNT=0"
        echo "CRITICAL_COUNT=0"
    fi
}

# Main processing
main() {
    local output_file="$1"
    local output_format="$2"

    echo "::group::Processing Results"

    if [ ! -f "$output_file" ]; then
        echo "::warning::Output file not found: $output_file"
        echo "FINDINGS_COUNT=0" >> "$GITHUB_OUTPUT"
        echo "CRITICAL_COUNT=0" >> "$GITHUB_OUTPUT"
        echo "::endgroup::"
        return 0
    fi

    # Count findings based on format
    case "$output_format" in
        json|semgrep-json)
            count_json_findings "$output_file" >> "$GITHUB_OUTPUT"
            ;;
        sarif)
            count_sarif_findings "$output_file" >> "$GITHUB_OUTPUT"
            ;;
        text|gitlab-sast|gitlab-secrets|junit-xml)
            count_text_findings "$output_file" >> "$GITHUB_OUTPUT"
            ;;
        *)
            echo "::warning::Unknown output format for counting: $output_format"
            echo "FINDINGS_COUNT=unknown" >> "$GITHUB_OUTPUT"
            echo "CRITICAL_COUNT=unknown" >> "$GITHUB_OUTPUT"
            ;;
    esac

    # Read back the values for display
    local findings_count critical_count
    findings_count=$(grep "FINDINGS_COUNT=" "$GITHUB_OUTPUT" | tail -1 | cut -d= -f2)
    critical_count=$(grep "CRITICAL_COUNT=" "$GITHUB_OUTPUT" | tail -1 | cut -d= -f2)

    echo "::notice::Scan Results: $findings_count total findings, $critical_count critical/high severity"

    # Set results file output
    echo "results-file=$output_file" >> "$GITHUB_OUTPUT"

    echo "::endgroup::"

    # Always return success - let the fail-on-findings step in action.yml handle workflow failure
    # This ensures the process-results step doesn't prematurely fail the action
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
