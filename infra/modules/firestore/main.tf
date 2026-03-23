# KAN-836: Habilitar Firestore
resource "google_project_service_identity" "firestore_sa" {
  provider = "google-beta"
  project  = var.project_id
  service  = "firestore.googleapis.com"
}

resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region # O una multiregión como "nam5"
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service_identity.firestore_sa]
}

# KAN-854: Índices compuestos
# Índice para 'providers' por 'active'
resource "google_firestore_index" "providers_active_index" {
  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = "providers"
  fields {
    field_path = "active"
    order      = "ASCENDING"
  }
}

# Índice para 'emission_factors' por 'transport_mode' y 'vehicle_type'
resource "google_firestore_index" "emission_factors_composite_index" {
  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = "emission_factors"
  fields {
    field_path = "transport_mode"
    order      = "ASCENDING"
  }
  fields {
    field_path = "vehicle_type"
    order      = "ASCENDING"
  }
}
