# KAN-837: Dataset de BigQuery
resource "google_bigquery_dataset" "emissions_data" {
  dataset_id = "emissions_data"
  project    = var.project_id
  location   = var.region
}

# KAN-837, KAN-878: Tabla de emisiones calculadas
resource "google_bigquery_table" "calculated_emissions" {
  dataset_id = google_bigquery_dataset.emissions_data.dataset_id
  table_id   = "calculated_emissions"
  project    = var.project_id

  # KAN-878: Particionamiento por fecha
  time_partitioning {
    type  = "DAY"
    field = "shipment_date"
  }

  # KAN-878: Clustering
  clustering = ["provider_id", "transport_mode"]

  # KAN-878: Requerir filtro de partición
  require_partition_filter = true

  # KAN-837: Esquema de la tabla
  schema = file("${path.module}/schemas/calculated_emissions.json")
}

# KAN-841: Permisos para QueryAPI
resource "google_project_iam_member" "query_api_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${var.query_api_sa_email}"
}
resource "google_project_iam_member" "query_api_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.query_api_sa_email}"
}
