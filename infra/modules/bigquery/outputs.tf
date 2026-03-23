output "dataset_id" {
  value = google_bigquery_dataset.emissions_data.dataset_id
}
output "table_id" {
  value = google_bigquery_table.calculated_emissions.table_id
}
