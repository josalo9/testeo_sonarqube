output "carrier_adapter_sa_email" {
  value = google_service_account.carrier_adapter_sa.email
}

output "query_api_sa_email" {
  value = google_service_account.query_api_sa.email
}

output "auth_service_sa_email" {
  value = google_service_account.auth_service_sa.email
}

output "ingestion_orchestrator_sa_email" {
  value = google_service_account.ingestion_orchestrator_sa.email
}

output "scheduler_sa_email" {
  value = google_service_account.scheduler_sa.email
}

output "eventarc_trigger_sa_email" {
  value = google_service_account.eventarc_trigger_sa.email
}

output "ingestion_sa_email" {
  value = google_service_account.ingestion_sa.email
}

output "analysis_sa_email" {
  value = google_service_account.analysis_sa.email
}
