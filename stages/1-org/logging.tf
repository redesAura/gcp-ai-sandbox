/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Modificado por redesAura (gcp-ai-sandbox)

locals {
  proyecto_logging = google_project.common["logging"].project_id

  filtro_logs = <<-EOF
    logName: /logs/cloudaudit.googleapis.com%2Factivity OR
    logName: /logs/cloudaudit.googleapis.com%2Fsystem_event OR
    logName: /logs/cloudaudit.googleapis.com%2Fdata_access OR
    logName: /logs/cloudaudit.googleapis.com%2Faccess_transparency OR
    logName: /logs/cloudaudit.googleapis.com%2Fpolicy OR
    logName: /logs/compute.googleapis.com%2Fvpc_flows OR
    logName: /logs/compute.googleapis.com%2Ffirewall OR
    logName: /logs/dns.googleapis.com%2Fdns_queries
  EOF
}

resource "google_organization_iam_audit_config" "org" {
  org_id  = var.org_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_logging_project_bucket_config" "auditoria" {
  project          = local.proyecto_logging
  location         = var.region
  bucket_id        = "auditoria-org"
  description      = "Logs de auditoría de toda la organización"
  retention_days   = var.dias_retencion_logs
  enable_analytics = true

  depends_on = [google_project_service.common]
}

resource "google_logging_organization_sink" "auditoria" {
  name             = "${var.prefijo_empresa}-auditoria-org"
  description      = "Logs de auditoría, red y DNS de la organización hacia el proyecto logging"
  org_id           = var.org_id
  destination      = "logging.googleapis.com/${google_logging_project_bucket_config.auditoria.id}"
  filter           = local.filtro_logs
  include_children = true
}

resource "google_project_iam_member" "sink_escribe_logs" {
  project = local.proyecto_logging
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.auditoria.writer_identity
}

# La exportación de facturación a este dataset se activa a mano en la consola de Billing
resource "google_bigquery_dataset" "facturacion" {
  #checkov:skip=CKV_GCP_81:Las llaves CMEK se crean en 2-security, que corre después de esta etapa
  dataset_id    = "facturacion"
  friendly_name = "Exportación de facturación"
  project       = local.proyecto_logging
  location      = var.region
  labels        = local.etiquetas

  depends_on = [google_project_service.common]
}
