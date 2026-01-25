# Security Policy

## About This Project

This project is a Starship prompt theme consisting of a single TOML configuration file (`starship.toml`). It does not contain executable code, only configuration directives interpreted by [Starship](https://starship.rs/).

## Scope

Since this is a configuration file:

- It cannot execute arbitrary code on its own
- It relies entirely on Starship's parsing and execution
- Security vulnerabilities would typically originate from Starship itself, not this theme

## Reporting a Concern

If you believe you have found a security issue related to this theme (e.g., a configuration that could lead to unexpected behavior), please:

1. **Do not open a public issue**
2. Contact the maintainer directly via email or GitHub private message
3. Provide a clear description of the concern and steps to reproduce

## For Starship Vulnerabilities

If the issue is with Starship itself (the prompt engine), please report it to the [Starship project](https://github.com/starship/starship/security).
