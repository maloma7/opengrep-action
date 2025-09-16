<!--
Copyright (c) 2025 maloma7. All rights reserved.
SPDX-License-Identifier: MIT
-->

# OpenGrep Action

A production-grade GitHub Action for running [OpenGrep](https://github.com/opengrep/opengrep) static analysis security testing with configurable rules, multiple output formats, and enterprise-grade security features.

[![GitHub release](https://img.shields.io/github/v/release/maloma7/opengrep-action?color=dc2626)](https://github.com/maloma7/opengrep-action/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-dc2626)](LICENSE)
[![Built with Claude](https://img.shields.io/badge/Built_with-Claude-dc2626?style=flat&logo=claude&logoColor=dc2626)](https://anthropic.com/claude-code)
[![OpenGrep](https://img.shields.io/badge/Powered_by-OpenGrep-dc2626?style=flat&logo=semgrep&logoColor=dc2626)](https://github.com/opengrep/opengrep)

## What is OpenGrep?

[OpenGrep](https://github.com/opengrep/opengrep) is a fork of Semgrep under the LGPL 2.1 license, providing advanced static code analysis for security vulnerabilities. It offers:

- **Multi-Language Support**: 30+ programming languages including JavaScript, Python, Java, Go, and more
- **Semantic Analysis**: Pattern matching that understands code structure, not just text
- **Community Rules**: Access to thousands of security rules from the community
- **High Performance**: Fast scanning optimized for CI/CD environments
- **Open Source**: Fully open source with no vendor lock-in

## Features

- **Fast Setup**: Automatic binary download and intelligent caching
- **Security-First**: Cosign signature verification for binary integrity
- **Multiple Outputs**: JSON, SARIF, text, GitLab SAST/Secrets, JUnit XML formats
- **Linux Optimized**: Native support for GitHub Actions runners (x86_64, ARM64)
- **High Performance**: Binary caching and efficient scanning algorithms
- **Enterprise Ready**: Robust error handling, timeout control, and comprehensive logging
- **Highly Configurable**: Custom rules, severity filtering, and flexible output options
- **Artifact Integration**: Seamless integration with GitHub Actions artifacts

## Installation

**No API keys or external services required** - completely self-contained with zero configuration beyond adding to your workflow.

Add to your GitHub Actions workflow:

```yaml
- name: OpenGrep Security Scan
  uses: maloma7/opengrep-action@v1
  with:
    paths: 'src app'
    output-format: 'sarif'
```

## Configuration

### 1. Basic Configuration

Add to your `.github/workflows/security.yml`:

```yaml
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run OpenGrep scan
        uses: maloma7/opengrep-action@v1
        with:
          paths: 'src app lib'
          output-format: 'sarif'
          severity: 'ERROR'
```

### 2. Advanced Configuration

Full configuration with all available options:

```yaml
- name: Comprehensive Security Scan
  uses: maloma7/opengrep-action@v1
  with:
    # OpenGrep Configuration
    version: 'v1.10.0'                    # OpenGrep version to use
    config: 'security/custom-rules.yml'    # Custom rules file or 'auto'
    paths: 'src app components'             # Paths to scan (space-separated)

    # Output Configuration
    output-format: 'sarif'                 # json, sarif, text, gitlab-sast, etc.
    output-file: 'security-results.sarif'  # Custom output filename

    # Scanning Options
    severity: 'WARNING'                     # INFO, WARNING, ERROR
    exclude: 'tests node_modules *.test.js' # Exclusion patterns
    max-target-bytes: '1000000'            # Max file size to scan
    timeout: '1800'                        # Scan timeout in seconds

    # Security & Behavior
    verify-signature: 'true'               # Verify binary signatures (recommended)
    fail-on-findings: 'true'               # Fail workflow on security findings
    upload-artifacts: 'true'               # Upload results as GitHub artifacts
    artifact-name: 'security-scan-results' # Custom artifact name
```

## How It Works

### Security Scanning Process

1. **Platform Detection**: Automatically detects GitHub runner architecture (x86_64/ARM64)
2. **Binary Management**: Downloads and caches OpenGrep binary with signature verification
3. **Rule Loading**: Loads security rules from auto-discovery, custom files, or registry
4. **Smart Scanning**: Efficiently scans specified paths with configurable exclusions
5. **Result Processing**: Generates structured output in your preferred format
6. **Artifact Upload**: Securely stores scan results in GitHub Actions artifacts

### Security Features

The action implements multiple layers of security:

#### Binary Integrity
- **Cosign Verification**: Automatically verifies OpenGrep binary signatures using Cosign
- **HTTPS Downloads**: All binaries downloaded over secure HTTPS connections
- **Checksum Validation**: Implicit validation through GitHub's release infrastructure

#### Secure Execution
- **No Credential Exposure**: Sanitized logging prevents accidental credential leakage
- **Fail-Safe Design**: Network errors don't expose sensitive information
- **Isolated Execution**: Runs in containerized GitHub Actions environment

### Output Formats

| Format | Use Case | Integration |
|--------|----------|-------------|
| `json` | General purpose, automation | APIs, custom processing |
| `sarif` | GitHub Security tab | GitHub Advanced Security |
| `text` | Human-readable output | Local development, debugging |
| `gitlab-sast` | GitLab integration | GitLab Security Dashboard |
| `gitlab-secrets` | Secret detection | GitLab Secret Detection |
| `junit-xml` | Test integration | CI/CD test reporting |
| `semgrep-json` | Legacy compatibility | Semgrep tooling migration |

## Usage Examples

### GitHub Security Integration

For repositories with GitHub Advanced Security:

```yaml
- name: Security Scan with SARIF
  uses: maloma7/opengrep-action@v1
  with:
    output-format: 'sarif'
    output-file: 'opengrep.sarif'
    severity: 'ERROR'
    fail-on-findings: 'false'  # Let Security tab handle reporting

- name: Upload SARIF results
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: opengrep.sarif
```

### Multi-Environment Strategy

```yaml
# Quick scan for pull requests
- name: PR Security Check
  if: github.event_name == 'pull_request'
  uses: maloma7/opengrep-action@v1
  with:
    severity: 'ERROR'
    timeout: '300'
    paths: ${{ steps.changed-files.outputs.files }}

# Comprehensive scan for main branch
- name: Full Security Audit
  if: github.ref == 'refs/heads/main'
  uses: maloma7/opengrep-action@v1
  with:
    config: '.github/security/comprehensive-rules.yml'
    severity: 'INFO'
    timeout: '1800'
    fail-on-findings: 'true'
```

### Custom Rules Configuration

```yaml
- name: Setup custom security rules
  run: |
    mkdir -p .github/security
    cat > .github/security/api-security.yml << 'EOF'
    rules:
      - id: hardcoded-api-key
        pattern: |
          const API_KEY = "$KEY"
        message: "Hardcoded API key detected"
        severity: ERROR
        languages: [javascript, typescript]

      - id: sql-injection-risk
        pattern: |
          db.query($USER_INPUT)
        message: "Potential SQL injection vulnerability"
        severity: ERROR
        languages: [javascript, typescript, python]
    EOF

- name: Run custom security scan
  uses: maloma7/opengrep-action@v1
  with:
    config: '.github/security/api-security.yml'
    paths: 'src api'
    output-format: 'json'
```

### Matrix Testing Strategy

```yaml
strategy:
  matrix:
    config:
      - { name: 'Security', rules: 'security/', severity: 'ERROR' }
      - { name: 'Quality', rules: 'quality/', severity: 'WARNING' }
      - { name: 'Performance', rules: 'performance/', severity: 'INFO' }

steps:
  - name: Run ${{ matrix.config.name }} Scan
    uses: maloma7/opengrep-action@v1
    with:
      config: ${{ matrix.config.rules }}
      severity: ${{ matrix.config.severity }}
      artifact-name: ${{ matrix.config.name }}-results
```

## Architecture

The action is built with a production-ready, modular architecture:

```
action.yml                 # Main action definition with inputs/outputs
├── Binary Management
│   ├── Platform detection (x86_64/ARM64)
│   ├── Intelligent caching with version keys
│   ├── Secure download with HTTPS
│   └── Cosign signature verification
├── Scanning Engine
│   ├── OpenGrep CLI integration
│   ├── Smart command building
│   ├── Timeout and resource management
│   └── Error handling with exit code mapping
├── Output Processing
│   ├── Multi-format result generation
│   ├── Finding classification and counting
│   ├── GitHub Actions output integration
│   └── Artifact upload with retention policies
└── Security & Validation
    ├── Binary integrity verification
    ├── Input validation and sanitization
    ├── Comprehensive error handling
    └── Secure logging without credential exposure
```

### Key Design Principles

1. **Security by Design**: Every component prioritizes security and integrity
2. **Performance Optimization**: Efficient caching, parallel processing, and resource management
3. **Reliability**: Comprehensive error handling with graceful degradation
4. **Observability**: Detailed logging and GitHub Actions integration
5. **Simplicity**: Minimal configuration with intelligent defaults

## Testing

The action includes comprehensive testing workflows:

```yaml
# Test basic functionality
- name: Test Basic Scan
  uses: maloma7/opengrep-action@v1
  with:
    paths: 'test/fixtures'
    verify-signature: 'false'  # Faster for testing

# Test with known vulnerable code
- name: Test Vulnerability Detection
  uses: maloma7/opengrep-action@v1
  with:
    paths: 'test/vulnerable-samples'
    fail-on-findings: 'false'  # We expect findings
```

### Test Coverage

- Multi-architecture support (x86_64, ARM64)
- All output formats validation
- Custom rule configuration
- Signature verification workflows
- Error handling and timeout scenarios
- Performance benchmarking

## Development

### Architecture Overview

The action leverages GitHub Actions composite run steps for maximum flexibility:

```yaml
runs:
  using: 'composite'
  steps:
    - name: Platform Detection      # Determine runner architecture
    - name: Binary Caching         # Intelligent version-based caching
    - name: Binary Download         # Secure download with verification
    - name: Signature Verification # Cosign-based integrity checking
    - name: OpenGrep Execution      # Configurable scanning with CLI
    - name: Result Processing       # Multi-format output handling
    - name: Artifact Upload         # GitHub Actions integration
```

### Contributing

We welcome contributions! However, please note:

1. **Security Focus**: All contributions must maintain or improve security posture
2. **Performance**: Changes should not significantly impact scan performance
3. **Compatibility**: Maintain backward compatibility with existing workflows
4. **Testing**: Include appropriate test coverage for new features

See our [issue templates](.github/ISSUE_TEMPLATE/) for bug reports and feature requests.

## API Reference

### OpenGrep CLI Integration

This action integrates with OpenGrep CLI commands:

- **`opengrep scan`**: Core scanning functionality with rule application
- **`opengrep --version`**: Version verification and validation
- **Configuration Flags**: `--config`, `--severity`, `--exclude`, `--timeout`
- **Output Formats**: `--json`, `--sarif`, `--text`, `--gitlab-sast`, etc.

For complete OpenGrep CLI documentation, visit: https://github.com/opengrep/opengrep

### Input Reference

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `version` | string | `v1.10.0` | OpenGrep version to download and use |
| `config` | string | `auto` | Rule configuration: 'auto', file path, or rule content |
| `paths` | string | `.` | Space-separated paths to scan |
| `output-format` | string | `json` | Output format: json, sarif, text, gitlab-sast, etc. |
| `output-file` | string | `opengrep-results.json` | Output file path |
| `severity` | string | `INFO` | Minimum severity: INFO, WARNING, ERROR |
| `exclude` | string | `` | Space-separated exclusion patterns |
| `max-target-bytes` | string | `1000000` | Maximum file size to scan (bytes) |
| `timeout` | string | `1800` | Scan timeout in seconds |
| `verify-signature` | boolean | `true` | Verify binary signature with Cosign |
| `fail-on-findings` | boolean | `false` | Fail workflow when findings detected |
| `upload-artifacts` | boolean | `true` | Upload results to GitHub artifacts |
| `artifact-name` | string | `opengrep-results` | Name for uploaded artifact |

### Output Reference

| Output | Type | Description |
|--------|------|-------------|
| `results-file` | string | Path to the generated results file |
| `findings-count` | number | Total number of security findings detected |
| `critical-count` | number | Number of high/critical severity findings |

## Troubleshooting

### Common Issues

**Action fails with "binary not found" error?**
- Verify the OpenGrep version exists in [releases](https://github.com/opengrep/opengrep/releases)
- Check runner architecture compatibility (x86_64/ARM64)
- Enable debug logging: Add `ACTIONS_RUNNER_DEBUG=true` to repository secrets

**Signature verification failures?**
```yaml
- name: Debug Signature Issues
  uses: maloma7/opengrep-action@v1
  with:
    verify-signature: 'false'  # Temporarily disable for testing
```
- Ensure runner has internet access to download signatures
- Check if corporate firewall blocks Cosign keyless verification
- Verify you're using an official OpenGrep release version

**No security findings detected?**
- Verify `paths` input includes your source code directories
- Check if `exclude` patterns are too broad
- Lower severity threshold: `severity: 'INFO'`
- Test with known vulnerable code samples

**Scan timeouts in large repositories?**
```yaml
- name: Extended Timeout Scan
  uses: maloma7/opengrep-action@v1
  with:
    timeout: '3600'  # 1 hour
    max-target-bytes: '5000000'  # Increase file size limit
```

### Debug Mode

Enable comprehensive debugging:

```yaml
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true

- name: Debug OpenGrep Scan
  uses: maloma7/opengrep-action@v1
  with:
    # ... your configuration
```

This provides:
- Binary download and verification details
- OpenGrep CLI command construction and execution
- Result processing and artifact upload information
- Performance timing and resource usage

### Platform-Specific Issues

**Linux ARM64 runners:**
- Ensure you're using `ubuntu-24.04-arm64` or compatible images
- ARM64 support requires OpenGrep v1.9.0 or later

**Self-hosted runners:**
- Verify internet access to `github.com` and `api.github.com`
- Ensure sufficient disk space for binary caching
- Check that `curl`, `tar`, and `cosign` are available

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **OpenGrep Team**: For maintaining the powerful open-source SAST engine
- **Semgrep Inc.**: For the original Semgrep project that OpenGrep builds upon
- **GitHub Actions Team**: For the robust CI/CD platform and security features

## Related Projects

- [OpenGrep](https://github.com/opengrep/opengrep) - The core static analysis engine
- [Semgrep](https://semgrep.dev/) - The original Semgrep project
- [GitHub Advanced Security](https://github.com/features/security) - Native GitHub security scanning

---

**Last Updated**: September 16, 2025
**Version**: 1.0.0

*This documentation is actively maintained and updated with each release. For the latest information, please check the [releases page](https://github.com/maloma7/opengrep-action/releases).*