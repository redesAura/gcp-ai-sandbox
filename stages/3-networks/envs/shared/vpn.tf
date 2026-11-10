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

// Modificado por redesAura (gcp-ai-sandbox) para dos túneles en us-central1.
// Se mantiene desactivado hasta cargar las IP públicas on-prem y crear el secreto PSK.

data "google_secret_manager_secret_version" "vpn_psk" {
  count   = var.enable_ha_vpn ? 1 : 0
  project = local.org_secret_project_id
  secret  = var.vpn_psk_secret_name
}

locals {
  org_secret_project_id = data.terraform_remote_state.org.outputs.org_secrets_project_id
  vpn_psk_secret_data = var.enable_ha_vpn ? chomp(data.google_secret_manager_secret_version.vpn_psk[0].secret_data) : null
}

module "vpn_ha" {
  count   = var.enable_ha_vpn ? 1 : 0
  source  = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version = "~> 7.0"

  project_id = local.net_hub_project_id
  region     = "us-central1"
  network    = module.shared_vpc.network_self_link
  name       = "vpn-c-svpc-hub-us-central1"

  router_asn = 64512
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "10.10.16.0/20"   = "Private Service Access"
      "10.10.32.0/22"   = "AI platform us-central1"
      "10.10.36.0/22"   = "GKE services us-central1"
      "10.10.44.0/24"   = "AI data us-central1"
      "10.10.48.0/23"   = "AI platform proxy-only us-central1"
      "10.10.64.0/19"   = "GKE pods us-central1"
      "10.10.128.0/22"  = "AI sandbox team 1"
      "10.10.132.0/22"  = "AI sandbox team 2"
      "10.10.136.0/22"  = "AI sandbox team 3"
      "10.20.32.0/22"   = "AI platform us-east4"
      "10.20.36.0/22"   = "GKE services us-east4"
      "10.20.48.0/23"   = "AI platform proxy-only us-east4"
      "10.20.64.0/20"   = "GKE pods us-east4"
      "10.255.255.10/32" = "PSC for Google APIs"
      "35.199.192.0/19"  = "Cloud DNS forwarding proxy source range"
    }
    mode = "CUSTOM"
  }

  peer_external_gateway = {
    redundancy_type = "TWO_IPS_REDUNDANCY"
    interfaces = [
      { id = 0, ip_address = var.vpn_peer_external_ip1 },
      { id = 1, ip_address = var.vpn_peer_external_ip2 }
    ]
  }

  tunnels = {
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = 65001
      }
      bgp_session_range               = "169.254.0.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      shared_secret                   = local.vpn_psk_secret_data
    }
    tunnel-2 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 65001
      }
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 1
      shared_secret                   = local.vpn_psk_secret_data
    }
  }

  depends_on = [module.shared_vpc]
}

resource "google_network_connectivity_spoke" "vpn_usc1" {
  count       = var.enable_ha_vpn ? 1 : 0
  name        = "vpn-spoke-c-svpc-hub-us-central1"
  project     = local.net_hub_project_id
  location    = "us-central1"
  hub         = module.shared_vpc.ncc_hub_uri
  group       = var.enable_hub_and_spoke_transitivity ? "default" : "center"
  description = "NCC spoke for the us-central1 HA VPN tunnels to on-premises."

  linked_vpn_tunnels {
    uris                       = try(module.vpn_ha[0].tunnel_self_links, [])
    site_to_site_data_transfer = false
  }
}
