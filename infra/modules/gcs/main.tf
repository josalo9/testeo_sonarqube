# KAN-833: Raw Data Lake Bucket
resource "google_storage_bucket" "raw_data_lake" {
  name          = "raw-data-lake-${var.project_id}"
  location      = var.region
  force_destroy = true

  # KAN-833, KAN-843: Habilitar versionamiento
  versioning {
    enabled = true
  }

  # KAN-833, KAN-843: Política de ciclo de vida
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age = 30
    }
  }
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 90
    }
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  # KAN-833: Habilitar logging de acceso
  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }
}

# Bucket para los logs de acceso
resource "google_storage_bucket" "access_logs" {
  name     = "gcs-access-logs-${var.project_id}"
  location = var.region
}

# KAN-833: Permisos IAM para el Raw Data Lake
# Rol de escritura para servicios de ingesta
resource "google_storage_bucket_iam_member" "ingestion_writer" {
  bucket = google_storage_bucket.raw_data_lake.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.ingestion_service_account_email}"
}
# Rol de lectura para analistas de datos
resource "google_storage_bucket_iam_member" "analysis_reader" {
  bucket = google_storage_bucket.raw_data_lake.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.analysis_service_account_email}"
}
# KAN-841: Permiso específico para CarrierAdapter
resource "google_storage_bucket_iam_member" "carrier_adapter_writer" {
  bucket = google_storage_bucket.raw_data_lake.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.carrier_adapter_sa_email}"
}


# KAN-840: Bucket para el Frontend
resource "google_storage_bucket" "frontend_assets" {
  name          = "frontend-assets-${var.project_id}"
  location      = var.region
  force_destroy = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # KAN-840: Habilitar versionamiento
  versioning {
    enabled = true
  }
}

# Hacer públicos los objetos del bucket del frontend
resource "google_storage_bucket_iam_member" "public_viewer" {
  bucket = google_storage_bucket.frontend_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
