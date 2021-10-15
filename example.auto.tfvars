okta_org_name  = "dev-123456"
okta_base_url  = "okta.com"
okta_api_token = ""

vault_addr="https://vault.your.corp:8200"
okta_base_url_full = "https://dev-123456.okta.com"
okta_allowed_groups=["vault_admins", "vault_devs"]
okta_mount_path="okta_oidc"
okta_auth_audience="api://vault"
cli_port=8250
roles = {
  okta_admin = {
    token_policies = ["admin-like-policy"]
    bound_groups = ["vault-admins"]
  },
  okta_devs  = {
    token_policies = ["demo-policy"]
    bound_groups = ["vault-devs"]
  }
}