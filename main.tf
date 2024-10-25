resource "azurerm_local_network_gateway" "AWS1" {
    name                = "${var.customer_gateway1}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP1
    address_space       = [var.customerCIDR]

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.21.1"
    }
}

resource "azurerm_local_network_gateway" "AWS2" {
    name                = "${var.customer_gateway2}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP2
    address_space       = [var.customerCIDR]

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.22.1"
    }
}

resource "azurerm_public_ip" "GatewayIP" {
    name                = "${var.GatewayIPName}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    allocation_method   = "Static"
}

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
        public_ip_address_id          = azurerm_public_ip.GatewayIP1.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    }

    bgp_settings {
        asn = 65002
        peering_addresses {
            ip_configuration_name = var.gatewayname
            apipa_addresses       = ["169.254.21.2", "169.254.22.2"]
        }
    }
}

resource "azurerm_virtual_network_gateway_connection" "Site2Site_Azure_AWS1" {
    name                           = "${var.ConnectionName1}_${var.environment}_Tunnel1"
    location                       = var.location
    resource_group_name            = "${var.rg_name}_${var.environment}"
    virtual_network_gateway_id     = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id       = azurerm_local_network_gateway.AWS1.id
    type                           = "IPsec"
    shared_key                     = var.shared_key
    enable_bgp                     = true
}

resource "azurerm_virtual_network_gateway_connection" "Site2Site_Azure_AWS2" {
    name                           = "${var.ConnectionName2}_${var.environment}_Tunnel2"
    location                       = var.location
    resource_group_name            = "${var.rg_name}_${var.environment}"
    virtual_network_gateway_id     = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id       = azurerm_local_network_gateway.AWS2.id
    type                           = "IPsec"
    shared_key                     = var.shared_key
    enable_bgp                     = true
}