output "project_name" {
  value = var.site
}

output "userca_key_openssh_pub" {
  value = tls_private_key.userca-key.public_key_openssh
}

output "hostca_key_openssh_pub" {
  value = tls_private_key.hostca-key.public_key_openssh
}

output "rotation_date" {
  value = time_static.rotate
}

output "expiration_date" {
  value = timeadd(time_rotating.key_rotation_interval.rotation_rfc3339, "720h")
}

output "all_projects" {
  value     = data.bitwarden-secrets_projects.all_projects
  sensitive = true
}

output "matching_project" {
  value = local.project_id
}

locals {
  # Map field_key (e.g. "priopenssh", "pubopenssh") -> index into key_comps
  key_comp_index = { for i, kc in local.key_comps : kc.field_key => i }
}

output "userca_key_creation_date" {
  value = bitwarden-secrets_secret.userca-key[local.key_comp_index["priopenssh"]].creation_date
}
output "userca_key_revision_date" {
  value = bitwarden-secrets_secret.userca-key[local.key_comp_index["priopenssh"]].revision_date
}
output "hostca_key_creation_date" {
  value = bitwarden-secrets_secret.hostca-key[local.key_comp_index["priopenssh"]].creation_date
}
output "hostca_key_revision_date" {
  value = bitwarden-secrets_secret.hostca-key[local.key_comp_index["priopenssh"]].revision_date
}

output "ansible_bws_secret_ids" {
  description = "Copy this block into the `bws_secret_ids:` map in ansible/roles/ssh_certificates/vars/main.yml. View with: tofu output -raw ansible_bws_secret_ids"
  value       = <<-EOT
    hostca-priopenssh: "${bitwarden-secrets_secret.hostca-key[local.key_comp_index["priopenssh"]].id}"
    hostca-pubopenssh: "${bitwarden-secrets_secret.hostca-key[local.key_comp_index["pubopenssh"]].id}"
    userca-priopenssh: "${bitwarden-secrets_secret.userca-key[local.key_comp_index["priopenssh"]].id}"
    userca-pubopenssh: "${bitwarden-secrets_secret.userca-key[local.key_comp_index["pubopenssh"]].id}"
  EOT
}
