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
  tags = {
    entorno = {
      descripcion = "Entorno al que pertenece el recurso"
      valores     = ["common", "ai-sandbox"]
    }
    sensibilidad = {
      descripcion = "Nivel de sensibilidad de un dataset; alta requiere aprobación del dueño de datos"
      valores     = ["baja", "media", "alta"]
    }
  }

  valores_tags = merge([
    for llave, tag in local.tags : {
      for valor in tag.valores : "${llave}/${valor}" => { llave = llave, valor = valor }
    }
  ]...)
}

resource "google_tags_tag_key" "org" {
  for_each = local.tags

  parent      = local.org
  short_name  = each.key
  description = each.value.descripcion
}

resource "google_tags_tag_value" "org" {
  for_each = local.valores_tags

  parent     = google_tags_tag_key.org[each.value.llave].id
  short_name = each.value.valor
}

resource "google_tags_tag_binding" "carpeta_common" {
  parent    = "//cloudresourcemanager.googleapis.com/${google_folder.common.name}"
  tag_value = google_tags_tag_value.org["entorno/common"].id
}

resource "google_tags_tag_binding" "carpeta_ai_sandbox" {
  parent    = "//cloudresourcemanager.googleapis.com/${google_folder.ai_sandbox.name}"
  tag_value = google_tags_tag_value.org["entorno/ai-sandbox"].id
}
