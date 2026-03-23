# KAN-840: Cloud CDN para el frontend
resource "google_compute_backend_bucket" "frontend_backend" {
  name        = "frontend-backend-bucket"
  bucket_name = var.frontend_bucket
  enable_cdn  = true
  project     = var.project_id
}

resource "google_compute_url_map" "url_map" {
  name            = "frontend-url-map"
  default_service = google_compute_backend_bucket.frontend_backend.id
  project         = var.project_id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "frontend-http-proxy"
  url_map = google_compute_url_map.url_map.id
  project = var.project_id
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "frontend-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  project    = var.project_id
}
