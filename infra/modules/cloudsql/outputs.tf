output "instance_connection_name" {
  value = google_sql_database_instance.postgres_instance.connection_name
}
output "db_name" {
  value = google_sql_database.user_management_db.name
}
output "db_user" {
  value = google_sql_user.auth_service_user.name
}
