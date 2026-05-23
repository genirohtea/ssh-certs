
variable "state_passphrase" {
  type        = string
  description = "The passphrase to encrypt the state with"
  sensitive   = true
}

######

variable "service" {
  type        = string
  description = "The name of the service"
  default     = "sshcerts"
}

variable "site" {
  type        = string
  description = "The name of the site"
  default     = "klaus"
}


########

variable "access_token" {
  type        = string
  description = "The access token to use for authentication."
  default     = null
}

variable "organization_id" {
  type        = string
  description = "The Bitwarden organization ID that owns the secrets."
  default     = null
}

variable "api_url" {
  type        = string
  description = "Bitwarden Secrets Manager API endpoint. Use https://api.bitwarden.eu for EU cloud or your self-hosted URL."
  default     = "https://api.bitwarden.com"
}

variable "identity_url" {
  type        = string
  description = "Bitwarden Identity endpoint. Use https://identity.bitwarden.eu for EU cloud or your self-hosted URL."
  default     = "https://identity.bitwarden.com"
}


########

variable "key_type" {
  description = "The key type"
  default     = "ED25519"
  type        = string
  validation {
    condition     = contains(["ECDSA", "RSA", "ED25519"], var.key_type)
    error_message = "The key_type must be one of the following: ECDSA, RSA, ED25519"
  }
}
