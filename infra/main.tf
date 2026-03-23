terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Habilitar APIs requeridas
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "firestore.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "eventarc.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
  ])
  project                     = var.project_id
  service                     = each.key
  disable_dependency_handling = true
}

# Red (VPC)
module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region
  depends_on = [google_project_service.apis]
}

# Cuentas de servicio y permisos IAM
module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  depends_on = [google_project_service.apis]
}

# Cloud Storage (KAN-833, KAN-840, KAN-843)
module "gcs" {
  source                        = "./modules/gcs"
  project_id                    = var.project_id
  region                        = var.region
  ingestion_service_account_email = module.iam.ingestion_sa_email
  analysis_service_account_email  = module.iam.analysis_sa_email
  carrier_adapter_sa_email      = module.iam.carrier_adapter_sa_email
  depends_on                    = [google_project_service.apis]
}

# Cloud SQL (KAN-834, KAN-845)
module "cloudsql" {
  source                     = "./modules/cloudsql"
  project_id                 = var.project_id
  region                     = var.region
  network_id                 = module.networking.vpc_id
  db_password                = var.db_password
  auth_service_account_email = module.iam.auth_service_sa_email
  depends_on                 = [google_project_service.apis]
}

# Memorystore Redis (KAN-835)
module "redis" {
  source     = "./modules/redis"
  project_id = var.project_id
  region     = var.region
  network_id = module.networking.vpc_id
  depends_on = [google_project_service.apis]
}

# Firestore (KAN-836, KAN-852, KAN-854)
module "firestore" {
  source     = "./modules/firestore"
  project_id = var.project_id
  region     = var.region
  depends_on = [google_project_service.apis]
}

# BigQuery (KAN-837, KAN-878)
module "bigquery" {
  source             = "./modules/bigquery"
  project_id         = var.project_id
  region             = var.region
  query_api_sa_email = module.iam.query_api_sa_email
  depends_on         = [google_project_service.apis]
}

# Pub/Sub (KAN-838, KAN-855)
module "pubsub" {
  source                          = "./modules/pubsub"
  project_id                      = var.project_id
  ingestion_orchestrator_sa_email = module.iam.ingestion_orchestrator_sa_email
  depends_on                      = [google_project_service.apis]
}

# Secret Manager (KAN-839)
module "secret_manager" {
  source     = "./modules/secret_manager"
  project_id = var.project_id
  secrets = {
    "db-credentials" = [module.iam.auth_service_sa_email]
    "provider-a-key" = [module.iam.auth_service_sa_email, module.iam.carrier_adapter_sa_email]
    "provider-b-key" = [module.iam.auth_service_sa_email, module.iam.carrier_adapter_sa_email]
  }
  depends_on = [google_project_service.apis]
}

# Cloud CDN (KAN-840)
module "cdn" {
  source          = "./modules/cdn"
  project_id      = var.project_id
  frontend_bucket = module.gcs.frontend_bucket_name
  depends_on      = [module.gcs]
}

# Cloud Function - IngestionOrchestrator (KAN-856)
module "cloud_function" {
  source                  = "./modules/cloud_function"
  project_id              = var.project_id
  region                  = var.region
  service_account_email   = module.iam.ingestion_orchestrator_sa_email
  ingestion_topic_id      = module.pubsub.sync_requests_topic_id
  depends_on              = [module.firestore, module.pubsub]
}

# Cloud Scheduler (KAN-857)
module "scheduler" {
  source                = "./modules/scheduler"
  project_id            = var.project_id
  region                = var.region
  function_uri          = module.cloud_function.function_uri
  service_account_email = module.iam.scheduler_sa_email
  depends_on            = [module.cloud_function]
}

# Eventarc (KAN-872)
module "eventarc" {
  source                  = "./modules/eventarc"
  project_id              = var.project_id
  region                  = var.region
  bucket_name             = module.gcs.raw_data_lake_bucket_name
  service_account_email   = module.iam.eventarc_trigger_sa_email
  depends_on              = [module.gcs]
}

# Monitoring (KAN-842, KAN-844, KAN-896)
module "monitoring" {
  source                  = "./modules/monitoring"
  project_id              = var.project_id
  region                  = var.region
  sync_scheduler_job_name = module.scheduler.job_name
  depends_on              = [google_project_service.apis]
}

# Audit Logging (KAN-842)
resource "google_project_iam_audit_config" "firestore_audit" {
  project = var.project_id
  service = "firestore.googleapis.com"
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_iam_audit_config" "secretmanager_audit" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  audit_log_config {
    log_type = "DATA_READ"
  }
}

resource "google_project_iam_audit_config" "bigquery_audit" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  audit_log_config {
    log_type = "DATA_READ"
  }
}

# Retención de logs (KAN-842)
resource "google_logging_project_bucket_config" "audit_log_retention" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "_Default"
  retention_days = 90
}
