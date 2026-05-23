terraform {
  required_providers {
    bitwarden-secrets = {
      source  = "bitwarden/bitwarden-secrets"
      version = "0.5.4-pre"
    }
  }

  # Opentofu encrypted state
  # https://opentofu.org/docs/language/state/encryption/
  encryption {
    key_provider "pbkdf2" "key" {
      # Specify a long / complex passphrase (min. 16 characters)
      passphrase = var.state_passphrase

      # Adjust the key length to the encryption method (default: 32)
      key_length = 32

      # Specify the number of iterations (min. 200.000, default: 600.000)
      iterations = 600000

      # Specify the salt length in bytes (default: 32)
      salt_length = 32

      # Specify the hash function (sha256 or sha512, default: sha512)
      hash_function = "sha512"
    }

    method "aes_gcm" "encrypt_method" {
      keys = key_provider.pbkdf2.key
    }

    state {
      # Encryption/decryption for state data
      method = method.aes_gcm.encrypt_method
    }

    plan {
      # Encryption/decryption for plan data
      method = method.aes_gcm.encrypt_method
    }

    remote_state_data_sources {
      # See below
    }
  }
}

# Configure the provider
provider "bitwarden-secrets" {
  access_token    = var.access_token
  organization_id = var.organization_id
  api_url         = var.api_url
  identity_url    = var.identity_url
}
