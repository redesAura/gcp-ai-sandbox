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

// EJEMPLO PENDIENTE: sustituir por resolutores on-prem reales alcanzables por HA VPN.
// 172.16.0.53 y .54 son marcadores, no valores confirmados.
// List of IPv4 address of target name servers for the forwarding zone configuration.
// See https://cloud.google.com/dns/docs/overview#dns-forwarding-zones

// HA VPN permanece apagada hasta confirmar IPs públicas on-prem y secreto PSK.
// Para habilitarla, define estas entradas en shared.auto.tfvars (no guardes el PSK aquí):
// enable_ha_vpn         = true
// vpn_peer_external_ip1 = "<ON_PREM_PUBLIC_IPV4_1>"
// vpn_peer_external_ip2 = "<ON_PREM_PUBLIC_IPV4_2>"
// vpn_psk_secret_name   = "<SECRET_MANAGER_SECRET_NAME>"
target_name_server_addresses = [
  {
    ipv4_address    = "172.16.0.53",
    forwarding_path = "default"
  },
  {
    ipv4_address    = "172.16.0.54",
    forwarding_path = "default"
  }
]
