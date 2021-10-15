# Okta config
resource "okta_group" "vault-admins" {
  name        = "vault-admins"
  description = ""
}

resource "okta_group" "vault-devs" {
  name        = "vault-devs"
  description = ""
}

resource "okta_app_oauth" "vault" {
  label       = "vault"
  type        = "web"
  grant_types = ["authorization_code", "implicit", "refresh_token"]
  redirect_uris = ["${var.vault_addr}/ui/vault/auth/${var.okta_mount_path}/oidc/callback",
    "${var.vault_addr}/oidc/callback",
    # the localhost on the cli port, usually 8250, is required below if you want to use CLI-based auth, ie
    # $ vault login -method=oidc -path=okta_oidc role=okta_admin
    "http://localhost:${var.cli_port}/oidc/callback"
  ]
  response_types            = ["id_token", "code"]
  consent_method            = "REQUIRED"
  post_logout_redirect_uris = [var.vault_addr]
  login_uri                 = "${var.vault_addr}/ui/vault/auth/${var.okta_mount_path}/oidc/callback"
  refresh_token_rotation    = "STATIC"
  lifecycle {
    ignore_changes = [groups]
  }
  groups_claim {
    type        = "FILTER"
    filter_type = "STARTS_WITH"
    name        = "groups"
    value       = "vault"
  }
}

resource "okta_app_oauth_api_scope" "vault" {
  app_id = okta_app_oauth.vault.id
  issuer = var.okta_base_url_full
  scopes = ["okta.groups.read", "okta.users.read.self"]
}

resource "okta_app_group_assignments" "vault-groups" {
  app_id = okta_app_oauth.vault.id
  group {
    id = okta_group.vault-admins.id
  }
  group {
    id = okta_group.vault-devs.id
  }
}

resource "okta_auth_server" "vault" {
  audiences   = [var.okta_auth_audience]
  description = ""
  name        = "vault"
  issuer_mode = "ORG_URL"
  status      = "ACTIVE"
}

resource "okta_auth_server_claim" "example" {
  auth_server_id          = okta_auth_server.vault.id
  name                    = "groups"
  value_type              = "GROUPS"
  group_filter_type       = "STARTS_WITH"
  value                   = "vault-"
  scopes                  = ["profile"]
  claim_type              = "IDENTITY"
  always_include_in_token = true
}

resource "okta_auth_server_policy" "vault" {
  auth_server_id   = okta_auth_server.vault.id
  status           = "ACTIVE"
  name             = "vault policy"
  description      = ""
  priority         = 1
  client_whitelist = ["ALL_CLIENTS"]
}

resource "okta_auth_server_policy_rule" "example" {
  auth_server_id       = okta_auth_server.vault.id
  policy_id            = okta_auth_server_policy.vault.id
  status               = "ACTIVE"
  name                 = "default"
  priority             = 1
  group_whitelist      = ["EVERYONE"]
  scope_whitelist      = ["*"]
  grant_type_whitelist = ["client_credentials", "authorization_code", "implicit"]
}

# Vault config
resource "vault_jwt_auth_backend" "okta_oidc" {
  description        = "Okta OIDC"
  path               = var.okta_mount_path
  type               = "oidc"
  oidc_discovery_url = okta_auth_server.vault.issuer
  bound_issuer       = okta_auth_server.vault.issuer
  oidc_client_id     = okta_app_oauth.vault.client_id
  oidc_client_secret = okta_app_oauth.vault.client_secret
  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = var.okta_default_lease_ttl
    max_lease_ttl      = var.okta_max_lease_ttl
    token_type         = var.okta_token_type
  }
}

resource "vault_jwt_auth_backend_role" "okta_role" {
  for_each       = var.roles
  backend        = vault_jwt_auth_backend.okta_oidc.path
  role_name      = each.key
  token_policies = each.value.token_policies

  allowed_redirect_uris = [
    "${var.vault_addr}/ui/vault/auth/${vault_jwt_auth_backend.okta_oidc.path}/oidc/callback",
    # This is for logging in with the CLI if you want.
    "http://localhost:${var.cli_port}/oidc/callback",
  ]

  user_claim      = "email"
  role_type       = "oidc"
  bound_audiences = [var.okta_auth_audience, okta_app_oauth.vault.client_id]
  # bound_audiences = [okta_auth_server.vault.audiences]
  oidc_scopes = [
    "openid",
    "profile",
    "email",
  ]
  bound_claims = {
    groups = join(",", each.value.bound_groups)
  }
  verbose_oidc_logging = true
}

# add KV for developers
resource "vault_mount" "developers" {
  type = "kv"
  path = "developers"
}
