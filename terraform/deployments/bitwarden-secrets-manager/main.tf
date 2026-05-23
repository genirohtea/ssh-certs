##### Key Creation

resource "time_rotating" "key_rotation_interval" {
  rotation_years = 1
}

resource "time_static" "rotate" {
  # Changes when the key is rotated
  rfc3339 = time_rotating.key_rotation_interval.id
}

resource "tls_private_key" "userca-key" {
  algorithm = var.key_type
  lifecycle {
    replace_triggered_by = [
      time_static.rotate
    ]
  }
}

resource "tls_private_key" "hostca-key" {
  algorithm = var.key_type
  lifecycle {
    replace_triggered_by = [
      time_static.rotate
    ]
  }
}

locals {
  key_comps = [
    { field_name = "private_key_openssh", field_key = "priopenssh" },
    { field_name = "private_key_pem", field_key = "pripem" },
    { field_name = "private_key_pem_pkcs8", field_key = "pripkcs8" },
    { field_name = "public_key_fingerprint_md5", field_key = "md5" },
    { field_name = "public_key_fingerprint_sha256", field_key = "sha256" },
    { field_name = "public_key_openssh", field_key = "pubopenssh" },
    { field_name = "public_key_pem", field_key = "pubpem" },
  ]

  userca_key_name = "kvk-${var.service}-${terraform.workspace}-${var.site}-userca"
  hostca_key_name = "kvk-${var.service}-${terraform.workspace}-${var.site}-hostca"
}

##### Project Finding

data "bitwarden-secrets_projects" "all_projects" {
}

locals {
  matching_projects = [
    for project in data.bitwarden-secrets_projects.all_projects.projects : project
    if project.name == var.site
  ]

  # If you are getting deadbeef, you must have the following setup:
  #   1. A BWS project with name == var.site
  #   2. Your BWS access token must have R/W permissions to that project
  project_id = length(local.matching_projects) == 1 ? local.matching_projects[0].id : "0xdeadbeef"
}

##### Storing the secret

resource "time_sleep" "wait_3_seconds" {
  create_duration = "3s"
}

resource "bitwarden-secrets_secret" "userca-key" {
  count = length(local.key_comps)

  key = format("%s-%s", local.userca_key_name, local.key_comps[count.index]["field_key"])

  value = tls_private_key.userca-key[local.key_comps[count.index]["field_name"]]

  note = jsonencode({
    content_type    = local.key_comps[count.index]["field_name"]
    expiration_date = timeadd(time_rotating.key_rotation_interval.rotation_rfc3339, "8760h") # 1 Year buffer on key expiration
    environment     = terraform.workspace
    service         = var.service
    site            = var.site
  })

  project_id = local.project_id

  # BWS rate limits aggressively, -parallelism 1 is required
  depends_on = [time_sleep.wait_3_seconds]
}

resource "bitwarden-secrets_secret" "hostca-key" {
  count = length(local.key_comps)

  key = format("%s-%s", local.hostca_key_name, local.key_comps[count.index]["field_key"])

  value = tls_private_key.hostca-key[local.key_comps[count.index]["field_name"]]

  note = jsonencode({
    content_type    = local.key_comps[count.index]["field_name"]
    expiration_date = timeadd(time_rotating.key_rotation_interval.rotation_rfc3339, "8760h") # 1 Year buffer on key expiration
    environment     = terraform.workspace
    service         = var.service
    site            = var.site
  })

  project_id = local.project_id

  # BWS rate limits aggressively, -parallelism 1 is required
  depends_on = [time_sleep.wait_3_seconds]
}
