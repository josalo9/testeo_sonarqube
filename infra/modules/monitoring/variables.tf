variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "query_api_service_name" {
  type    = string
  default = "query-api" # Valor por defecto
}
variable "sync_scheduler_job_name" {
  type    = string
  default = "sync-scheduler-job" # Valor por defecto
}
