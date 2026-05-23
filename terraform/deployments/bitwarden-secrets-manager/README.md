# Bitwarden Secrets Manager

## Required Pre-req

### Local Machine

Edit `terraform.tfvars` to include `state_passphrase = "<state_password>"`, then:

```sh
tofu init
tofu workspace new prod
tofu plan
tofu apply
```

## Using

```sh
terraform init -backend-config klaus_curie_dev_backend.hcl -upgrade
terraform workspace new dev
```

References:

- <https://stackoverflow.com/questions/72331158/terraform-different-backend-for-each-project>
- <https://www.reddit.com/r/Terraform/comments/1bgzgm1/terraform_workspace_and_repositories_set_up/>
- <https://github.com/terraform-google-modules/terraform-example-foundation/blob/master/0-bootstrap/main.tf>
