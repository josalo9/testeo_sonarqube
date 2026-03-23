variable "project_id" {
  type = string
}

variable "secrets" {
  description = "Un mapa de nombres de secretos a una lista de emails de SA que pueden acceder a ellos."
  type        = map(list(string))
  default     = {}
}
