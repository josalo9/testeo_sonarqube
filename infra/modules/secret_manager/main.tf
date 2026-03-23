# KAN-839: Habilitar Secret Manager y crear secretos para proveedores
resource "google_secret_manager_secret" "provider_secrets" {
  for_each = var.secrets

  secret_id = each.key
  project   = var.project_id
  replication {
    automatic = true
  }
}

# Itera sobre cada secreto y sus miembros para dar permisos
resource "google_secret_manager_secret_iam_binding" "secret_accessors" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = google_secret_manager_secret.provider_secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    for sa_email in each.value : "serviceAccount:${sa_email}"
  ]
}
