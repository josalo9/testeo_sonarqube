output "vpc_id" {
  description = "El ID de la VPC creada."
  value       = google_compute_network.vpc_network.id
}
