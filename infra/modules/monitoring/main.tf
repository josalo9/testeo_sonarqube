# KAN-844: Cuota de BigQuery
# La actualización de cuotas mediante Terraform no es un recurso directo.
# Se recomienda hacerlo con un script gcloud o manualmente.
# `gcloud alpha services quota update --service=bigquery.googleapis.com --consumer=projects/PROJECT_ID --metric=bigquery.googleapis.com/query/scanned_bytes --unit=1/d/project --value=1099511627776`
# A continuación se crean las alertas de monitoreo.

# KAN-844, KAN-896: Políticas de Alerta
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Equipo SRE (Email)"
  type         = "email"
  labels = {
    email_address = "sre-team@example.com" # Reemplazar con email real
  }
  project = var.project_id
}

# KAN-896: Alerta para fallos de SyncScheduler
resource "google_monitoring_alert_policy" "sync_scheduler_failure" {
  display_name = "[KAN-896] SyncScheduler Job Failed Consecutively"
  project      = var.project_id
  combiner     = "AND"
  conditions {
    display_name = "SyncScheduler job has failed"
    condition_threshold {
      filter          = "resource.type = \"cloud_scheduler_job\" AND metric.type = \"cloudscheduler.googleapis.com/job/execution_count\" AND resource.labels.job_id = \"${var.sync_scheduler_job_name}\" AND metric.labels.status = \"FAILED\""
      duration        = "180s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1 # Más de 1 fallo en 3 minutos
      trigger {
        count = 2
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email_channel.id]
}

# KAN-896: Alerta para latencia de QueryAPI
resource "google_monitoring_alert_policy" "query_api_latency" {
  display_name = "[KAN-896] QueryAPI High Latency"
  project      = var.project_id
  combiner     = "OR"
  conditions {
    display_name = "Latency over 5s"
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\" AND resource.labels.service_name = \"${var.query_api_service_name}\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5000 # 5 segundos en ms
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email_channel.id]
}

# KAN-844: Alerta para cuota de BigQuery
resource "google_monitoring_alert_policy" "bigquery_quota" {
  display_name = "[KAN-844] BigQuery Scanned Data Quota at 80%"
  project      = var.project_id
  combiner     = "OR"
  conditions {
    display_name = "Scanned bytes quota usage > 80%"
    condition_monitoring_query_language {
      query    = "fetch consumer_quota::cloud.googleapis.com/serviceusage/quota/limit | metric 'bigquery.googleapis.com/query/scanned_bytes' | group_by [], [value_limit: limit()] | { value / value_limit } | condition gt(0.8)"
      duration = "0s"
      trigger {
        count = 1
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email_channel.id]
}
