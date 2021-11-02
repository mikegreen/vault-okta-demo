terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.24"
    }
    okta = {
      source  = "okta/okta"
      version = "~> 3.15"
    }
  }
}

# Configure the Okta Provider
provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}

provider "vault" {
  address = var.vault_addr
  namespace= var.vault_namespace
  # token = "<your token here> or set as VAULT_TOKEN env var"

  # use admin namespace for HCP Vault
  # namespace = "admin"
}
