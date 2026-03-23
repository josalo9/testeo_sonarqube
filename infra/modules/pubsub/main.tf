# KAN-838: Topic para solicitudes de sincronización
resource "google_pubsub_topic" "sync_requests" {
  name    = "sync-requests"
  project = var.project_id
}

# KAN-838: Topic para datos crudos recibidos
resource "google_pubsub_topic" "raw_data_landed" {
  name    = "raw-data-landed"
  project = var.project_id
}

# KAN-855: Topic para Dead Letter Queue
resource "google_pubsub_topic" "sync_requests_dlq" {
  name    = "sync-requests-dlq"
  project = var.project_id
}

# KAN-838: Suscripción para sync-requests
resource "google_pubsub_subscription" "sync_requests_sub" {
  name    = "sync-requests-sub"
  topic   = google_pubsub_topic.sync_requests.name
  project = var.project_id

  # KAN-855: Configuración de DLQ
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.sync_requests_dlq.id
    max_delivery_attempts = 5
  }
}

# KAN-838: Suscripción para raw-data-landed
resource "google_pubsub_subscription" "raw_data_landed_sub" {
  name    = "raw-data-landed-sub"
  topic   = google_pubsub_topic.raw_data_landed.name
  project = var.project_id
}

# Permisos para que IngestionOrchestrator publique en sync-requests
resource "google_pubsub_topic_iam_member" "ingestion_orchestrator_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.sync_requests.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.ingestion_orchestrator_sa_email}"
}
