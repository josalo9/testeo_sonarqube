# KAN-841: Cuenta de servicio para CarrierAdapter
resource "google_service_account" "carrier_adapter_sa" {
  account_id   = "carrier-adapter-sa"
  display_name = "Service Account for CarrierAdapter"
  project      = var.project_id
}

# KAN-841: Cuenta de servicio para QueryAPI
resource "google_service_account" "query_api_sa" {
  account_id   = "query-api-sa"
  display_name = "Service Account for QueryAPI"
  project      = var.project_id
}

# Cuenta de servicio para AuthService
resource "google_service_account" "auth_service_sa" {
  account_id   = "auth-service-sa"
  display_name = "Service Account for AuthService"
  project      = var.project_id
}

# Cuenta de servicio para IngestionOrchestrator (Cloud Function)
resource "google_service_account" "ingestion_orchestrator_sa" {
  account_id   = "ingestion-orchestrator-sa"
  display_name = "Service Account for Ingestion Orchestrator"
  project      = var.project_id
}

# Cuenta de servicio para Cloud Scheduler
resource "google_service_account" "scheduler_sa" {
  account_id   = "scheduler-sa"
  display_name = "Service Account for Cloud Scheduler"
  project      = var.project_id
}

# Cuenta de servicio para Eventarc Trigger
resource "google_service_account" "eventarc_trigger_sa" {
  account_id   = "eventarc-trigger-sa"
  display_name = "Service Account for Eventarc Triggers"
  project      = var.project_id
}

# Roles para IngestionOrchestrator (KAN-856)
resource "google_project_iam_member" "ingestion_orchestrator_firestore" {
  project = var.project_id
  role    = "roles/datastore.user" # Permite leer de Firestore
  member  = "serviceAccount:${google_service_account.ingestion_orchestrator_sa.email}"
}

resource "google_project_iam_member" "ingestion_orchestrator_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher" # Permite publicar en Pub/Sub
  member  = "serviceAccount:${google_service_account.ingestion_orchestrator_sa.email}"
}

# Rol para que Cloud Scheduler invoque la Cloud Function (KAN-857)
resource "google_project_iam_member" "scheduler_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Roles para Eventarc (KAN-872)
resource "google_project_iam_member" "eventarc_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_trigger_sa.email}"
}
resource "google_project_iam_member" "eventarc_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_trigger_sa.email}"
}
# Permisos para que la SA de Eventarc pueda ser usada por el trigger
resource "google_service_account_iam_member" "eventarc_sa_user" {
  service_account_id = google_service_account.eventarc_trigger_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[gcp-sa/eventarc]"
}

# Roles para servicios de ingesta y análisis (KAN-833)
resource "google_service_account" "ingestion_sa" {
  account_id   = "ingestion-services-sa"
  display_name = "Generic SA for Ingestion Services"
  project      = var.project_id
}

resource "google_service_account" "analysis_sa" {
  account_id   = "data-analysts-sa"
  display_name = "Generic SA for Data Analysts"
  project      = var.project_id
}
