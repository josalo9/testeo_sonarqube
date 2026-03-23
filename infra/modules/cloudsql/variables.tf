variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "network_id" {
  type = string
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "auth_service_account_email" {
  type = string
}

variable "db_admin_password" {
  description = "La contraseña para el usuario administrador 'postgres'."
  type        = string
  sensitive   = true
}
