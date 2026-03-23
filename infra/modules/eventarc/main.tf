# KAN-872: Eventarc Trigger para nuevos archivos en RawDataLake
resource "google_eventarc_trigger" "raw_data_upload_trigger" {
  name     = "raw-data-upload-trigger"
  location = var.region
  project  = var.project_id

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }
  # KAN-872: Filtrar por archivos .json
  event_data_content_type = "application/json"

  # El destino (CalculationEngine) se debe configurar aquí.
  # Como no se conoce el nombre del servicio Cloud Run, se deja comentado.
  # Para que funcione, descomente y reemplace con los valores correctos.
  /*
  destination {
    cloud_run_service {
      service = var.calculation_engine_service_name
      region  = var.calculation_engine_service_region
    }
  }
  */

  service_account = var.service_account_email
}
