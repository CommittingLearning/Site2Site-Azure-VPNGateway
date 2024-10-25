variable "azure_subscription_id" {
    description = "The Subscription ID for the Azure account"
    type        = string
}

variable "azure_client_id" {
    description = "The Client ID (App ID) for the Azure Service Principal"
    type        = string 
}

variable "azure_tenant_id" {
    description = "The Tenant ID for the Azure account"
    type        = string
}

variable "rg_name" {
    description = "Name of the Resource Group"
    default     = "Site2Site_rg"
}

variable "location" {
    description = "Region of Deployment"
    default     = "West US"
}

variable "environment" {
    description = "The environment (e.g., development, production) to append to the VNet name"
    type        = string
}

variable "customer_gateway1" {
    description = "Name of the first customer gateway endpoint"
    type        = string
    default     = "AWSVGW1"
}

variable "customer_gateway2" {
    description = "Name of the first customer gateway endpoint"
    type        = string
    default     = "AWSVGW2"
}

variable "customerIP1" {
    description = "Public IP Address of the Customer VPN Gateway 1"
    type = string
    default = "52.34.235.202"
}

variable "customerIP2" {
    description = "Public IP Address of the Customer VPN Gateway 2"
    type = string
    default = "52.35.21.204"
}

variable "customerCIDR" {
    description = "Private CIDR range of the customer LAN"
    type        = string
    default     = "192.168.0.0/16"
}

variable "GatewayIPName" {
    description = "Name of the dedicated public IP resource attachded to the Vnet gateway 1"
    type        = string
    default     = "VnetGatewayIP"
}

variable "vnetgatewayname" {
    description = "Name of the VNet gateway resource to provision"
    type        = string
    default     = "S2SVnetGate"
}

variable "vpntype" {
    description = "Type of VPN connection to be established"
    type        = string
    default     = "RouteBased"
}

variable "gatewaysku" {
    description = "SKU of the VNet gateway being provisioned"
    type        = string
    default     = "VpnGw1"
}

variable "ConnectionName1" {
    description = "Name of the VPN Connection between Azure and AWS"
    type        = string
    default     = "S2S-AWS-Azure1"
}

variable "ConnectionName2" {
    description = "Name of the VPN Connection between Azure and AWS"
    type        = string
    default     = "S2S-AWS-Azure2"
}

variable "shared_key" {
    description = "The shared key value to establish VPN connection"
    type        = string
    sensitive   = true
}

variable "gatewayname" {
    description = "Name of the 1st ip config"
    type        = string
    default     = "gateway_ip"
}