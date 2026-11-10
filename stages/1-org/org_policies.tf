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
  politicas_booleanas = toset([
    "compute.disableNestedVirtualization",
    "compute.disableSerialPortAccess",
    "compute.disableVpcExternalIpv6",
    "compute.requireOsLogin",
    "compute.restrictXpnProjectLienRemoval",
    "compute.setNewProjectDefaultToZonalDNSOnly",
    "compute.skipDefaultNetworkCreation",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
    "iam.disableServiceAccountKeyCreation",
    "iam.disableServiceAccountKeyUpload",
    "sql.restrictAuthorizedNetworks",
    "sql.restrictPublicIp",
    "storage.publicAccessPrevention",
    "storage.uniformBucketLevelAccess",
  ])
}

resource "google_org_policy_policy" "booleana" {
  for_each = local.politicas_booleanas

  name   = "${local.org}/policies/${each.value}"
  parent = local.org

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "regiones_permitidas" {
  name   = "${local.org}/policies/gcp.resourceLocations"
  parent = local.org

  spec {
    rules {
      values {
        allowed_values = [for r in var.regiones_permitidas : "in:${r}-locations"]
      }
    }
  }
}

resource "google_org_policy_policy" "sin_ip_publica_vm" {
  name   = "${local.org}/policies/compute.vmExternalIpAccess"
  parent = local.org

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "forwarding_solo_interno" {
  name   = "${local.org}/policies/compute.restrictProtocolForwardingCreationForTypes"
  parent = local.org

  spec {
    rules {
      values {
        allowed_values = ["INTERNAL"]
      }
    }
  }
}

resource "google_org_policy_policy" "contactos_del_dominio" {
  name   = "${local.org}/policies/essentialcontacts.allowedContactDomains"
  parent = local.org

  spec {
    rules {
      values {
        allowed_values = ["@${var.dominio}"]
      }
    }
  }
}

resource "google_org_policy_policy" "dominios_iam" {
  count = length(var.ids_cliente_permitidos) > 0 ? 1 : 0

  name   = "${local.org}/policies/iam.allowedPolicyMemberDomains"
  parent = local.org

  spec {
    rules {
      values {
        allowed_values = var.ids_cliente_permitidos
      }
    }
  }

  depends_on = [
    google_project_iam_member.sink_escribe_logs,
    google_organization_iam_member.grupos,
    google_project_iam_member.grupos,
    google_bigquery_dataset_iam_member.grupos,
  ]
}

# Carpeta ai-sandbox: aislamiento y CMEK obligatorio

resource "google_org_policy_policy" "sandbox_vpc_compartida" {
  name   = "${google_folder.ai_sandbox.name}/policies/compute.restrictSharedVpcHostProjects"
  parent = google_folder.ai_sandbox.name

  spec {
    rules {
      values {
        allowed_values = [
          "under:${google_folder.common.name}",
          "under:${google_folder.ai_sandbox.name}",
        ]
      }
    }
  }
}

resource "google_org_policy_policy" "sandbox_cmek_obligatorio" {
  name   = "${google_folder.ai_sandbox.name}/policies/gcp.restrictNonCmekServices"
  parent = google_folder.ai_sandbox.name

  spec {
    rules {
      values {
        denied_values = var.servicios_cmek_obligatorio
      }
    }
  }
}

resource "google_org_policy_policy" "sandbox_llaves_de_security" {
  name   = "${google_folder.ai_sandbox.name}/policies/gcp.restrictCmekCryptoKeyProjects"
  parent = google_folder.ai_sandbox.name

  spec {
    rules {
      values {
        allowed_values = ["under:projects/${google_project.common["security"].project_id}"]
      }
    }
  }
}
