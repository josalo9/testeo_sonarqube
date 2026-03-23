# KAN-835: Instancia de Memorystore Redis
resource "google_redis_instance" "cache" {
  name               = "main-cache"
  tier               = "BASIC" # Para desarrollo
  memory_size_gb     = 1
  location_id        = var.region
  project            = var.project_id
  authorized_network = var.network_id
  redis_configs = {
    "maxmemory-policy" = "allkeys-lru" # KAN-835: Política de desalojo
  }
}
