# Changelog

All notable changes to this module are documented in this file.

## 2026-11-19 — Allow HTTP Event Stream URLs and optional TLS skip

### Added
- `skip_tls_verify` input (default `true`) mapped to `terracurl_request.skip_tls_verify`

### Changed
- `eda_event_stream_url` validation now accepts `http://` and `https://`

## 2026-11-19 — Add gitleaks pre-commit hook

### Added
- `gitleaks` hook in `.pre-commit-config.yaml` to block commits that introduce secrets

## 2026-11-19 — Add changelog and pre-commit hooks

### Added
- `CHANGELOG.md` for dated Keep a Changelog entries
- `.pre-commit-config.yaml` with formatting, validation, TFLint, and terraform-docs hooks
- `.tflint.hcl` with the Terraform recommended preset
- `.terraform-docs.yml` to inject Requirements, Providers, Inputs, and Outputs into `README.md`

## 2026-11-19 — Initial EDA notifier module

### Added
- Reusable Terraform module that POSTs apply events to an AAP EDA event stream
- Ephemeral `local_command` readers for the HCP workload-identity token, workspace name, and run ID
- `terraform_data` trigger with optional every-apply nonce via `trigger_on_every_apply`
- `terracurl_request` using write-only headers and body so the OIDC token stays out of plan and state
- Module inputs: `eda_event_stream_url`, `event_type`, `outputs`, `trigger_on_every_apply`
- README with usage, design notes, and private-registry publish steps
