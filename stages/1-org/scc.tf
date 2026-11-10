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

resource "google_pubsub_topic" "scc" {
  #checkov:skip=CKV_GCP_83:Las llaves CMEK se crean en 2-security, que corre después de esta etapa
  count = var.habilitar_scc ? 1 : 0

  name    = "scc-hallazgos"
  project = google_project.common["security"].project_id
  labels  = local.etiquetas

  depends_on = [google_project_service.common]
}

resource "google_pubsub_subscription" "scc" {
  count = var.habilitar_scc ? 1 : 0

  name                       = "scc-hallazgos-sub"
  topic                      = google_pubsub_topic.scc[0].id
  project                    = google_project.common["security"].project_id
  message_retention_duration = "604800s" # 7 días
  labels                     = local.etiquetas
}

resource "google_scc_v2_organization_notification_config" "hallazgos_activos" {
  count = var.habilitar_scc ? 1 : 0

  config_id    = "hallazgos-activos"
  organization = var.org_id
  location     = "global"
  description  = "Hallazgos activos de Security Command Center"
  pubsub_topic = google_pubsub_topic.scc[0].id

  streaming_config {
    filter = "state = \"ACTIVE\""
  }
}
