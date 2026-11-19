# terraform-zjleblanc-eda-notifier

Reusable Terraform module that notifies an Ansible Automation Platform (AAP) Event-Driven Ansible (EDA) event stream after a successful apply. Workspaces pass an `event_type` and non-sensitive outputs; the module reads the HCP Terraform workload-identity OIDC token and run metadata at apply time and POSTs a JSON event to the Event Stream URL.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.7 |
| <a name="requirement_terracurl"></a> [terracurl](#requirement\_terracurl) | ~> 2.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terracurl"></a> [terracurl](#provider\_terracurl) | ~> 2.8 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_eda_event_stream_url"></a> [eda\_event\_stream\_url](#input\_eda\_event\_stream\_url) | AAP Event Stream POST URL. Automatically populated when TF\_VAR\_eda\_event\_stream\_url is set in an HCP Variable Set. | `string` | n/a | yes |
| <a name="input_event_type"></a> [event\_type](#input\_event\_type) | Routing key matched by EDA rules to select the target Ansible Job Template. | `string` | `"terraform.apply.completed"` | no |
| <a name="input_outputs"></a> [outputs](#input\_outputs) | Map of Terraform outputs to include in the EDA event payload. Do not pass secrets—values are stored in terraform\_data state. | `any` | `{}` | no |
| <a name="input_skip_tls_verify"></a> [skip\_tls\_verify](#input\_skip\_tls\_verify) | When true, disables TLS certificate verification for the Event Stream POST (useful for private AAP with internal CAs). | `bool` | `true` | no |
| <a name="input_trigger_on_every_apply"></a> [trigger\_on\_every\_apply](#input\_trigger\_on\_every\_apply) | When false, triggers EDA only when values in `outputs` change. Set to true to fire on every apply. | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

HCP Terraform must mint a workload-identity token and supply the Event Stream URL. Typically that is done once via an organization Variable Set:

| Category | Key | Purpose |
|----------|-----|---------|
| env | `TFC_WORKLOAD_IDENTITY_AUDIENCE` | Audience claimed by the OIDC token (must match the EDA JWT credential) |
| env | `TF_VAR_eda_event_stream_url` | Supplies `eda_event_stream_url` to every workspace |

## Design note (write-only POST)

The design guide sketched a Terraform `action "terracurl_request"` that interpolated ephemeral `local_command` stdout into the Authorization header. Terraform 1.14+ rejects ephemeral values on non-write-only action attributes (action plans are stored in the plan file; see [hashicorp/terraform#38390](https://github.com/hashicorp/terraform/issues/38390)), and terracurl actions do not expose write-only headers.

This module keeps the same caller contract and still avoids persisting the OIDC token. It uses:

1. Ephemeral `local_command` to read `TFC_WORKLOAD_IDENTITY_TOKEN`, `TFC_WORKSPACE_NAME`, and `TFC_RUN_ID`
2. A `terraform_data` trigger whose `input` changes when `event_type`, `outputs`, or (optionally) every apply should fire
3. A `terracurl_request` resource with write-only `headers_wo` / `request_body_wo`, `skip_destroy = true`, and `replace_triggered_by` on the trigger

A replacement create POSTs again with a fresh token. Destroy skips the HTTP call. Unchanged trigger values do not notify, even when the token rotates each run.

## Usage

```hcl
module "eda_notify" {
  source  = "app.terraform.io/my-org/eda-notifier/zjleblanc"
  version = "~> 1.0"

  event_type = "app.infrastructure.deployed"
  outputs = {
    lb_dns      = aws_lb.main.dns_name
    db_endpoint = aws_rds_cluster.db.endpoint
    vpc_id      = module.vpc.vpc_id
  }
}
```

Because `outputs` references provisioned attributes, Terraform waits for those resources before notifying EDA.

> **Do not pass secrets in `outputs`.** Values assigned to `terraform_data.eda_trigger.input` are stored in Terraform state. Pass identifiers (for example Secrets Manager ARNs or Vault paths) so Ansible can fetch secrets itself.

### Registry naming

HCP Terraform publishes modules from repositories named `terraform-<PROVIDER>-<NAME>`. This repo name yields:

```text
app.terraform.io/<org>/eda-notifier/zjleblanc
```

The design guide’s `.../eda-notifier/null` address requires a Git remote named `terraform-null-eda-notifier` before publish.

## Token payload

```json
{
  "jti": "1192426d-b525-4fde-9d42-f238be437bbd",
  "iss": "https://app.terraform.io",
  "aud": "my-example-audience",
  "iat": 1650486122,
  "nbf": 1650486117,
  "exp": 1650486422,
  "sub": "organization:my-org:project:Default Project:workspace:my-workspace:run_phase:apply",
  "terraform_organization_id": "org-GRNbCjYNpBB6NEH9",
  "terraform_organization_name": "my-org",
  "terraform_project_id": "prj-vegSA59s1XPwMr2t",
  "terraform_project_name": "Default Project",
  "terraform_workspace_id": "ws-mbsd5E3Ktt5Rg2Xm",
  "terraform_workspace_name": "my-workspace",
  "terraform_full_workspace": "organization:my-org:project:Default Project:workspace:my-workspace",
  "terraform_run_id": "run-X3n1AUXNGWbfECsJ",
  "terraform_run_phase": "apply"
}
```

## Event payload

```json
{
  "event_type": "<var.event_type>",
  "workspace": "<TFC_WORKSPACE_NAME>",
  "run_id": "<TFC_RUN_ID>",
  "outputs": {}
}
```

The request uses `Authorization: Bearer <TFC_WORKLOAD_IDENTITY_TOKEN>` and accepts HTTP `200` or `202`.

## Development

Install [pre-commit](https://pre-commit.com/), [TFLint](https://github.com/terraform-linters/tflint), and [terraform-docs](https://terraform-docs.io/), then:

```bash
pre-commit install
pre-commit run --all-files
```

Hooks run `terraform fmt`, `terraform validate`, TFLint, terraform-docs (README inject), and gitleaks.

## Publish to the private registry

1. Tag a release: `git tag v1.0.0 && git push --tags`
2. In HCP Terraform: **Registry → Publish → Module**, connect this repository, and publish

## License

[MIT](LICENSE)
