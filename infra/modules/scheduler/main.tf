# KAN-857: Cloud Scheduler para sincronizaciones horarias
resource "google_cloud_scheduler_job" "sync_scheduler" {
  name        = "sync-scheduler-job"
  description = "Dispara el IngestionOrchestrator cada hora"
  schedule    = "0 * * * *" # Cada hora
  time_zone   = "Etc/UTC"
  project     = var.project_id
  region      = var.region

  # KAN-857: Reintentos con exponential backoff
  retry_config {
    retry_count          = 3
    max_retry_duration   = "3600s"
    min_backoff_duration = "5s"
    max_backoff_duration = "600s"
  }

  http_target {
    uri         = var.function_uri
    http_method = "POST"

    # KAN-857: Autenticación con OIDC
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
}
