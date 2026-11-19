terraform {
  required_version = ">= 1.14.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 2.8"
    }
  }
}
