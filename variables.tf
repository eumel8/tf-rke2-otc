####################
# Environment
####################

variable "environment" {
  default = "rke2-test"
}

####################
#   OTC auth config
####################

variable "region" {
  default = "eu-de"
}

variable "otc_domain" {
  default = "eu-de"
}

variable "auth_url" {
  default = "https://iam.eu-de.otc.t-systems.com:443/v3"
}

variable "tenant_name" {
  default = "eu-de"
}

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "key" {
  default = ""
}

####################
# VPC vars
####################

variable "vpc_cidr" {
  description = "CIDR of the VPC"  
  default     = "10.1.0.0/24"
}

####################
# Subnet vars
####################

variable "subnet_cidr" {
  description = "CIDR of the Subnet"  
  default     = "10.1.0.0/24"
}

variable "subnet_gateway_ip" {
  description = "Default gateway of the Subnet"  
  default     = "10.1.0.1"
}

variable "subnet_primary_dns" {
  description = "Primary DNS server of the Subnet"  
  default     = "100.125.4.25"
}

variable "subnet_secondary_dns" {
  description = "Secondary DNS server of the Subnet"  
  default     = "100.125.129.199"
}

####################
# ECS vars
####################

variable "availability_zone1" {
  description = "Availability Zone 1 (Biere)"
  default     = "eu-de-01"
}

variable "availability_zone2" {
  description = "Availability Zone 2 (Magdeburg)"
  default     = "eu-de-02"
}

variable "availability_zone3" {
  description = "Availability Zone 3 (Biere)"
  default     = "eu-de-03"
}

variable "image_name_server-1" {
  description = "Name of the image"
  default     = "Standard_Ubuntu_20.04_latest"
}

variable "image_name_server-2" {
  description = "Name of the image"
  default     = "Standard_Ubuntu_20.04_latest"
}

variable "flavor_id" {
  description = "ID of Flavor"
  default     = "c3.large.4"
}

variable "public_key" {
  description = "ssh public key to use"
  default     = ""
}

variable "power_state" {
  description = "Power state of ECS instances"
  default     = "active"
}

variable "deploy_wireguard" {
  description = "Deploy a Wireguard Server to access the internal network"
  default     = false
  type        = bool
} 

variable "wg_server_address" {
  description = "Ip address of the Wireguard Server"
  default     = "10.2.0.1/24"
}

variable "wg_server_port" {
  description = "Port  of the Wireguard Server"
  default     = "51820"
}

variable "wg_server_private_key" {
  description = "Wireguard Server Private Key"
  default     = ""
}

variable "wg_server_public_key" {
  description = "Wireguard Server Public Key"
  default     = ""
}

variable "wg_peer_address" {
  description = "Wireguard Server Public Key"
  default     = "10.2.0.2/24"
}

variable "wg_peer_public_key" {
  description = "Wireguard Peer Public Key"
  default     = ""
}

####################
# DNS vars
####################

variable "create_dns" {
  description = "Create DNS entries"
  type        = bool
  default     = false
}

variable "rancher_host" {
  description = "Public host of the rancher instance"
  default     = "rancher"
}

variable "rancher_domain" {
  description = "Public domain of the rancher instance"
  default     = "example.com"
}

variable "admin_email" {
  description = "Admin email address for DNS and LetsEncrypt"
  default     = "nobody@example.com"
}

####################
# RKE2S/K8S vars
####################

variable "rke2_version" {
  description = "RKE2 install version or channel, e.g stable/latest, v1.20.7+rke2r2"
  default     = "stable"
}

variable "cert-manager_version" {
  description = "Cert-Manager chart version"
  default     = "v1.8.1"
}

variable "token" {
  description = "RKE Server Token"
  default     = "12345678"
}

####################
# Rancher vars
####################

variable "rancher_version" {
  description = "Version of Rancher app"
  default     = "v2.7.0"
}
