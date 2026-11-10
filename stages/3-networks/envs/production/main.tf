/**
 * Copyright 2022 Google LLC
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

// Modificado por redesAura (gcp-ai-sandbox) para el plan de red del reto.

locals {
  env              = "production"
  environment_code = substr(local.env, 0, 1)

  private_service_cidr = "10.10.16.0/20"
  subnet_primary_ranges = {
    (local.default_region1) = "10.10.32.0/22"
    (local.default_region2) = "10.20.32.0/22"
  }
  subnet_proxy_ranges = {
    (local.default_region1) = "10.10.48.0/23"
    (local.default_region2) = "10.20.48.0/23"
  }
  subnet_secondary_ranges = {
    (local.default_region1) = [
      {
        range_name    = "gke-pods-usc1"
        ip_cidr_range = "10.10.64.0/19"
      },
      {
        range_name    = "gke-services-usc1"
        ip_cidr_range = "10.10.36.0/22"
      }
    ],
    (local.default_region2) = [
      {
        range_name    = "gke-pods-use4"
        ip_cidr_range = "10.20.64.0/20"
      },
      {
        range_name    = "gke-services-use4"
        ip_cidr_range = "10.20.36.0/22"
      }
    ]
  }
}

module "base_env" {
  source = "../../modules/base_env"

  env                               = local.env
  environment_code                  = local.environment_code
  default_region1                   = local.default_region1
  default_region2                   = local.default_region2
  domain                            = var.domain
  enable_partner_interconnect       = false
  enable_hub_and_spoke_transitivity = var.enable_hub_and_spoke_transitivity
  private_service_cidr              = local.private_service_cidr
  subnet_primary_ranges             = local.subnet_primary_ranges
  subnet_proxy_ranges               = local.subnet_proxy_ranges
  subnet_secondary_ranges           = local.subnet_secondary_ranges
  private_service_connect_ip        = "10.255.255.10"
  remote_state_bucket               = var.remote_state_bucket
  tfc_org_name                      = var.tfc_org_name
}
