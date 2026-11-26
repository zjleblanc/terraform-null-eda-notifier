# Minimal usage of zjleblanc/eda-notifier/null.
#
# At apply time (HCP Terraform), the workspace must provide:
# - env TFC_WORKLOAD_IDENTITY_AUDIENCE (OIDC audience matching the EDA JWT credential)
# - env TF_VAR_eda_event_stream_url (or pass eda_event_stream_url explicitly)
# - env TFC_WORKLOAD_IDENTITY_TOKEN, TFC_WORKSPACE_NAME, TFC_RUN_ID (minted by HCP)

terraform {
  required_version = ">= 1.14.0"
}

module "eda_notify" {
  source = "../.."

  eda_event_stream_url = var.eda_event_stream_url
  event_type           = "terraform.apply.completed"
  outputs = {
    example = "replace-with-non-secret-resource-attributes"
  }
}
