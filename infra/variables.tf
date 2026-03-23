variable "project_id" {
  description = "El ID del proyecto de Google Cloud."
  type        = string
}

variable "region" {
  description = "La región principal para los recursos de GCP."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "La zona principal para los recursos de GCP."
  type        = string
  default     = "us-central1-a"
}

variable "db_password" {
  description = "La contraseña para el usuario de la base de datos de Cloud SQL. Debe ser proporcionada de forma segura."
  type        = string
  sensitive   = true
}

variable "db_admin_password" {
  description = "La contraseña para el usuario administrador 'postgres' de Cloud SQL. Debe ser proporcionada de forma segura."
  type        = string
  sensitive   = true
}
