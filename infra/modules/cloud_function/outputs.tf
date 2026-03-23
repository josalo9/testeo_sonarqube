output "function_uri" {
  value = google_cloudfunctions2_function.ingestion_orchestrator.service_config[0].uri
}
