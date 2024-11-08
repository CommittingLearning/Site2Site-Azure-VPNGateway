# Creating a local network gateway to connect with the first AWS S2S tunnel
resource "azurerm_local_network_gateway" "AWS1" {
    name                = "${var.customer_gateway1}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP1

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.21.1"
    }
}

# Creating a local network gateway to connect with the second AWS S2S tunnel
resource "azurerm_local_network_gateway" "AWS2" {
    name                = "${var.customer_gateway2}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP2

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.22.1"
    }
}

# Provisioning a dedicated public IP to attach to the VNet Gateway
resource "azurerm_public_ip" "GatewayIP" {
    name                = "${var.GatewayIPName}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    allocation_method   = "Static"
}

# Provisioning a VNet Gateway
resource "azurerm_virtual_network_gateway" "VnetGateway" {
    name                = "${var.vnetgatewayname}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"

    type     = "Vpn"
    vpn_type = var.vpntype

    active_active = false
    enable_bgp    = true
    sku           = var.gatewaysku

    ip_configuration {
        name                          = var.gatewayname
        public_ip_address_id          = azurerm_public_ip.GatewayIP.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    }

    bgp_settings {
        asn = 65002
        peering_addresses {
            ip_configuration_name = var.gatewayname
            apipa_addresses       = [var.custombgp1, var.custombgp2]
        }
    }
}

# Creating a VNet connection to sync the first local network gateway with the VNet Gateway
resource "azurerm_virtual_network_gateway_connection" "Site2Site_Azure_AWS1" {
    name                       = "${var.ConnectionName1}_${var.environment}_Tunnel1"
    location                   = var.location
    resource_group_name        = "${var.rg_name}_${var.environment}"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.AWS1.id
    type                       = "IPsec"
    shared_key                 = var.shared_key
    enable_bgp                 = true
    dpd_timeout_seconds        = 45

    custom_bgp_addresses {
        primary = var.custombgp1
    }
}

# Creating a VNet connection to sync the second local network gateway with the VNet Gateway
resource "azurerm_virtual_network_gateway_connection" "Site2Site_Azure_AWS2" {
    name                       = "${var.ConnectionName2}_${var.environment}_Tunnel2"
    location                   = var.location
    resource_group_name        = "${var.rg_name}_${var.environment}"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.AWS2.id
    type                       = "IPsec"
    shared_key                 = var.shared_key
    enable_bgp                 = true
    dpd_timeout_seconds        = 45
    
    custom_bgp_addresses {
        primary = var.custombgp2
    }
}