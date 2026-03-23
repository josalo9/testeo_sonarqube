output "raw_data_lake_bucket_name" {
  value = google_storage_bucket.raw_data_lake.name
}

output "frontend_bucket_name" {
  value = google_storage_bucket.frontend_assets.name
}
