# vault-okta-demo

## Prerequisites 

## 

## Troubleshooting

`Error exchanging oidc code: "Provider.Exchange: id_token failed verification: Provider.VerifyIDToken: invalid id_token audiences: verifyAudiences: invalid id_token audiences: invalid audience".`

This means the `bound_audiences` for the `vault_jwt_auth_backend_role` that Vault is trying are missing/invalid. 
Ensure the terraform created app client_id (not the client_id variable set) and `api://vault` are in the role, ie:
```
            "bound_audiences": [
              "0oa4rr3i4dydl3pMf4x7",
              "api://vault"
            ],
```

