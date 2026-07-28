###############################################################################
# Outputs: Generated README and HTML dashboard
###############################################################################

resource "local_file" "readme_md" {
  filename = "${path.module}/out/README.md"
  content  = templatefile("${path.module}/README.md.tftpl", {
    project_id             = var.project_id
    region                 = var.region
    gcs_dev_name           = module.gcs_dev.name
    gcs_test_name          = module.gcs_test.name
    gcs_prod_name          = module.gcs_prod.name
    sql_instance_name      = google_sql_database_instance.main.name
    sql_database_name      = google_sql_database.database.name
    sql_connection_name    = google_sql_database_instance.main.connection_name
    sql_user_name          = google_sql_user.rails_user.name
    cloud_run_service_name = google_cloud_run_v2_service.rails_app.name
    cloud_run_service_uri  = google_cloud_run_v2_service.rails_app.uri
    admin_password         = random_password.admin_password.result
  })
}

resource "local_file" "readme_html" {
  filename = "${path.module}/out/OUTPUT.html"
  content  = <<-EOT
    <html>
      <head>
        <title>Rails 8 GCP Infrastructure</title>
        <style>
          body { font-family: sans-serif; margin: 40px; line-height: 1.6; }
          h1 { color: #d32f2f; }
          h2 { color: #1976d2; border-bottom: 2px solid #1976d2; padding-bottom: 5px; }
          ul { list-style-type: none; padding-left: 0; }
          li { margin-bottom: 10px; padding: 10px; background: #f5f5f5; border-radius: 5px; }
          a { color: #00796b; text-decoration: none; font-weight: bold; }
          a:hover { text-decoration: underline; }
          code { background: #e0e0e0; padding: 2px 4px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>🚀 Rails 8 GCP Infrastructure</h1>
        <p>Welcome to your dynamically generated infrastructure output!</p>

        <h2>🪣 ActiveStorage Buckets</h2>
        <ul>
          <li>🟡 <strong>Dev</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_dev.name}?project=${var.project_id}">gs://${module.gcs_dev.name}</a></li>
          <li>🔵 <strong>Test</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_test.name}?project=${var.project_id}">gs://${module.gcs_test.name}</a></li>
          <li>🟢 <strong>Prod</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_prod.name}?project=${var.project_id}">gs://${module.gcs_prod.name}</a></li>
        </ul>

        <h2>🐘 Cloud SQL (PostgreSQL)</h2>
        <ul>
          <li><strong>Instance</strong>: <a href="https://console.cloud.google.com/sql/instances/${google_sql_database_instance.main.name}/overview?project=${var.project_id}">${google_sql_database_instance.main.name}</a></li>
          <li><strong>Database</strong>: ${google_sql_database.database.name}</li>
          <li><strong>Connection Name</strong>: <code>${google_sql_database_instance.main.connection_name}</code></li>
          <li><strong>DB User</strong>: <code>${google_sql_user.rails_user.name}</code></li>
        </ul>

        <h2>🏃 Cloud Run</h2>
        <ul>
          <li><strong>Service</strong>: <a href="https://console.cloud.google.com/run/detail/${var.region}/${google_cloud_run_v2_service.rails_app.name}/metrics?project=${var.project_id}">${google_cloud_run_v2_service.rails_app.name}</a></li>
          <li><strong>URL</strong>: <a href="${google_cloud_run_v2_service.rails_app.uri}">${google_cloud_run_v2_service.rails_app.uri}</a></li>
        </ul>

        <h2>🔐 Secret Manager</h2>
        <ul>
          <li><strong>rails-master-key</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-master-key/versions?project=${var.project_id}">View in Secret Manager</a></li>
          <li><strong>rails-db-password</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-db-password/versions?project=${var.project_id}">View in Secret Manager</a></li>
          <li><strong>rails-admin-password</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-admin-password/versions?project=${var.project_id}">View in Secret Manager</a> (Value: <code>${random_password.admin_password.result}</code>)</li>
        </ul>
      </body>
    </html>
  EOT
}
