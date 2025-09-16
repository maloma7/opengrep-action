<!--
Copyright (c) 2025 maloma7. All rights reserved.
SPDX-License-Identifier: MIT
-->

# Changelog

All notable changes to the OpenGrep GitHub Action will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-16

### Initial Release

Production-grade GitHub Action for running OpenGrep static analysis security testing with enterprise-grade features and comprehensive platform support.

### Added

#### Core Features
- **OpenGrep Integration**: Full integration with OpenGrep v1.10.0 static analysis engine
- **Multi-Architecture Support**: Native support for Linux x86_64 and ARM64 runners
- **Intelligent Binary Management**: Automatic download, caching, and version management
- **Security-First Design**: Cosign signature verification for binary integrity by default

#### Output Formats
- **JSON Output**: Standard JSON format for programmatic processing
- **SARIF Support**: GitHub Advanced Security integration with SARIF format
- **Text Output**: Human-readable format for debugging and local development
- **GitLab Integration**: Native GitLab SAST and Secrets format support
- **JUnit XML**: Test integration and CI/CD reporting format
- **Semgrep Compatibility**: Legacy Semgrep JSON format support

#### Configuration Options
- **Auto Rule Discovery**: Automatic rule detection with `config: auto`
- **Custom Rules**: Support for custom rule files and configurations
- **Path Targeting**: Configurable scan paths with inclusion/exclusion patterns
- **Severity Filtering**: Configurable severity levels (INFO, WARNING, ERROR)
- **Timeout Control**: Configurable scan timeouts and resource limits
- **File Size Limits**: Configurable maximum file size scanning

#### Security Features
- **Cosign Verification**: Automatic binary signature verification using Cosign
- **Secure Downloads**: All binaries downloaded over HTTPS from official releases
- **No Credential Exposure**: Sanitized logging prevents accidental credential leakage
- **Fail-Safe Design**: Network errors don't compromise security posture

#### Performance Optimizations
- **Binary Caching**: Intelligent version-based caching for faster subsequent runs
- **Platform Detection**: Automatic runner architecture detection
- **Resource Management**: Efficient memory and CPU usage with timeout controls
- **Concurrent Processing**: Optimized for GitHub Actions runner environments

#### GitHub Actions Integration
- **Artifact Upload**: Automatic results upload with configurable retention
- **Output Variables**: Structured outputs for workflow integration
- **Error Handling**: Comprehensive exit code mapping and error reporting
- **Logging Integration**: Native GitHub Actions logging with grouping

#### Enterprise Features
- **Signature Verification**: Required by default, can be disabled for testing
- **Comprehensive Logging**: Detailed operation logs for debugging and monitoring
- **Error Recovery**: Graceful handling of network issues and timeout scenarios
- **Input Validation**: Robust validation of all user inputs and configurations

### Technical Implementation

#### Architecture
- **Composite Action**: Built using GitHub Actions composite run steps
- **Modular Design**: Separated concerns for maintainability and testing
- **Platform Agnostic**: Supports both x86_64 and ARM64 Linux runners
- **Version Management**: Flexible OpenGrep version specification

#### CLI Integration
- **Command Building**: Smart command construction with proper flag handling
- **Exit Code Mapping**: Proper interpretation of OpenGrep exit codes
- **Output Processing**: Multi-format result parsing and classification
- **Error Handling**: Comprehensive error handling with actionable messages

#### Security Implementation
- **Binary Integrity**: Full Cosign-based signature verification workflow
- **Secure Execution**: Isolated execution environment with proper cleanup
- **Input Sanitization**: All user inputs validated and sanitized
- **Audit Trail**: Comprehensive logging for security auditing

### Documentation
- **Comprehensive README**: Production-grade documentation with examples
- **API Reference**: Complete input/output documentation with types
- **Troubleshooting Guide**: Detailed troubleshooting with code examples
- **Architecture Documentation**: Technical implementation details
- **Usage Examples**: Real-world workflow configurations
- **Security Guide**: Best practices for secure usage

### GitHub Templates
- **Issue Templates**: Tailored bug report and feature request templates
- **Contributing Guide**: Clear contribution guidelines and policies
- **Security Policy**: GitHub Security Advisories integration

### Supported Platforms
- **GitHub Actions Runners**: All standard Ubuntu runners (ubuntu-latest, ubuntu-20.04, ubuntu-22.04)
- **ARM64 Support**: Ubuntu ARM64 runners (ubuntu-24.04-arm64)
- **Self-Hosted Runners**: Compatible with self-hosted Linux runners
- **Container Support**: Works in containerized GitHub Actions environments

### Default Configuration
- **OpenGrep Version**: v1.10.0 (latest stable release)
- **Output Format**: JSON (most versatile for automation)
- **Scan Paths**: Current directory (.)
- **Severity Level**: INFO (comprehensive scanning)
- **Signature Verification**: Enabled (security-first approach)
- **Artifact Upload**: Enabled (preserve results)
- **Timeout**: 1800 seconds (30 minutes)

### Breaking Changes
- None (initial release)

### Migration Notes
- None (initial release)

### Known Issues
- None at release

### Contributors
- **maloma7**: Initial development and implementation
- **Claude Code**: AI-assisted development and documentation

---

*This changelog follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format to ensure clear communication of changes across versions.*