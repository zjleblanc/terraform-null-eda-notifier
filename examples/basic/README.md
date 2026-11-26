# Basic example

Calls the root module with a sample `event_type` and non-secret `outputs`.

## Prerequisites

This module is intended for **HCP Terraform** applies. Before apply, configure:

| Category | Key | Purpose |
|----------|-----|---------|
| env | `TFC_WORKLOAD_IDENTITY_AUDIENCE` | Audience claimed by the OIDC token (must match the EDA JWT credential) |
| env | `TF_VAR_eda_event_stream_url` | Supplies `eda_event_stream_url` (or pass the variable explicitly) |

HCP also injects `TFC_WORKLOAD_IDENTITY_TOKEN`, `TFC_WORKSPACE_NAME`, and `TFC_RUN_ID` during the run.

## Usage

```hcl
module "eda_notify" {
  source  = "zjleblanc/eda-notifier/null"
  version = "~> 1.0"

  event_type = "terraform.apply.completed"
  outputs = {
    example = "non-secret-value"
  }
}
```

Do not pass secrets in `outputs`; they are stored in Terraform state via the module trigger.
