variable "project_id" {
  description = "El ID del proyecto de Google Cloud."
  type        = string
}

variable "region" {
  description = "La región para los buckets."
  type        = string
}

variable "ingestion_service_account_email" {
  description = "Email de la SA para servicios de ingesta."
  type        = string
}

variable "analysis_service_account_email" {
  description = "Email de la SA para analistas de datos."
  type        = string
}

variable "carrier_adapter_sa_email" {
  description = "Email de la SA para CarrierAdapter."
  type        = string
}
