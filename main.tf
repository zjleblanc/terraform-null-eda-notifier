# Read the short-lived OIDC JWT and HCP run metadata ephemerally in memory.
# Ephemeral resources are never persisted to Terraform state or plan files.
ephemeral "local_command" "oidc_token" {
  command   = "printenv"
  arguments = ["TFC_WORKLOAD_IDENTITY_TOKEN"]
}

ephemeral "local_command" "workspace_name" {
  command   = "printenv"
  arguments = ["TFC_WORKSPACE_NAME"]
}

ephemeral "local_command" "run_id" {
  command   = "printenv"
  arguments = ["TFC_RUN_ID"]
}

# Fires only after infrastructure creates or updates—never during terraform destroy.
# Changing input replaces terracurl_request via replace_triggered_by, which POSTs again.
resource "terraform_data" "eda_trigger" {
  input = {
    event_type = var.event_type
    outputs    = var.outputs
    nonce      = var.trigger_on_every_apply ? timestamp() : "static"
  }
}

# HTTP POST on create. skip_destroy keeps destroy silent.
# Write-only headers/body keep the OIDC token out of plan and state (actions cannot
# accept ephemeral values; see hashicorp/terraform#38390).
resource "terracurl_request" "notify_eda" {
  name           = "eda-notify"
  method         = "POST"
  url            = var.eda_event_stream_url
  response_codes = ["200", "202"]
  max_retry      = 3
  retry_interval = 2
  skip_read      = true
  skip_destroy   = true

  headers_wo = {
    Authorization = "Bearer ${trimspace(ephemeral.local_command.oidc_token.stdout)}"
    Content-Type  = "application/json"
  }
  headers_wo_version = 1

  request_body_wo = jsonencode({
    event_type = var.event_type
    workspace  = trimspace(ephemeral.local_command.workspace_name.stdout)
    run_id     = trimspace(ephemeral.local_command.run_id.stdout)
    outputs    = var.outputs
  })
  request_body_wo_version = 1

  lifecycle {
    replace_triggered_by = [terraform_data.eda_trigger]
  }
}
