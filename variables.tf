variable "eda_event_stream_url" {
  type        = string
  description = "AAP Event Stream POST URL. Automatically populated when TF_VAR_eda_event_stream_url is set in an HCP Variable Set."

  validation {
    condition     = startswith(var.eda_event_stream_url, "https://")
    error_message = "eda_event_stream_url must be an https:// URL."
  }
}

variable "event_type" {
  type        = string
  default     = "terraform.apply.completed"
  description = "Routing key matched by EDA rules to select the target Ansible Job Template."
}

variable "outputs" {
  type        = any
  default     = {}
  description = "Map of Terraform outputs to include in the EDA event payload. Do not pass secrets—values are stored in terraform_data state."
}

variable "trigger_on_every_apply" {
  type        = bool
  default     = false
  description = "When false, triggers EDA only when values in `outputs` change. Set to true to fire on every apply."
}
