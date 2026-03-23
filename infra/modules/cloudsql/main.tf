# KAN-834: Instancia de Cloud SQL PostgreSQL
resource "google_sql_database_instance" "postgres_instance" {
  name             = "user-management-instance"
  database_version = "POSTGRES_13"
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-f1-micro" # Usar un tier pequeño para desarrollo
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }
  }

  deletion_protection = false # Para poder destruir en desarrollo
}

# KAN-834: Base de datos
resource "google_sql_database" "user_management_db" {
  name     = "user_management_db"
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
}

# KAN-834: Usuario de la base de datos
resource "google_sql_user" "auth_service_user" {
  name     = "auth_service_user"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
  project  = var.project_id
}

# KAN-834: Almacenar credenciales en Secret Manager
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "db-credentials"
  project   = var.project_id
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_credentials_version" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    host     = google_sql_database_instance.postgres_instance.private_ip_address
    dbname   = google_sql_database.user_management_db.name
    user     = google_sql_user.auth_service_user.name
    password = var.db_password
  })
}

# KAN-834: Permiso para que AuthService acceda al secreto
resource "google_secret_manager_secret_iam_member" "auth_service_secret_accessor" {
  project   = google_secret_manager_secret.db_credentials.project
  secret_id = google_secret_manager_secret.db_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.auth_service_account_email}"
}
