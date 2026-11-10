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
  categorias_contacto = {
    BILLING         = [var.grupos.facturacion]
    LEGAL           = [var.grupos.plataforma, var.grupos.auditoria]
    PRODUCT_UPDATES = [var.grupos.plataforma]
    SECURITY        = [var.grupos.seguridad]
    SUSPENSION      = [var.grupos.plataforma, var.grupos.seguridad]
    TECHNICAL       = [var.grupos.plataforma]
  }

  contactos = transpose(local.categorias_contacto)
}

resource "google_essential_contacts_contact" "org" {
  for_each = local.contactos

  parent                              = local.org
  email                               = each.key
  language_tag                        = var.idioma_contactos
  notification_category_subscriptions = each.value

  depends_on = [google_org_policy_policy.contactos_del_dominio]
}
