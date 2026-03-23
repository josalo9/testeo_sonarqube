# KAN-856: Cloud Function - IngestionOrchestrator
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.root}/functions/ingestion_orchestrator"
  output_path = "/tmp/ingestion_orchestrator.zip"
}

resource "google_storage_bucket" "functions_bucket" {
  name     = "cf-source-bucket-${var.project_id}"
  location = var.region
  project  = var.project_id
}

resource "google_storage_bucket_object" "archive" {
  name   = "ingestion_orchestrator.zip#${data.archive_file.source.output_md5}"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.source.output_path
}

resource "google_cloudfunctions2_function" "ingestion_orchestrator" {
  name     = "ingestion-orchestrator"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "go121" # Usar una versión reciente de Go
    entry_point = "IngestionOrchestrator"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256Mi"
    timeout_seconds       = 60
    service_account_email = var.service_account_email
    environment_variables = {
      GCP_PROJECT        = var.project_id
      INGESTION_TOPIC_ID = var.ingestion_topic_id
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  location = google_cloudfunctions2_function.ingestion_orchestrator.location
  service  = google_cloudfunctions2_function.ingestion_orchestrator.name
  project  = google_cloudfunctions2_function.ingestion_orchestrator.project
  role     = "roles/run.invoker"
  member   = "allUsers" # Para que Cloud Scheduler pueda invocarla
}
