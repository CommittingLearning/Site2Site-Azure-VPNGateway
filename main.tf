resource "azurerm_local_network_gateway" "AWS" {
    name                = "${var.customer_gateway}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP
    address_space       = [var.customerCIDR]

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.167.61"
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
        public_ip_address_id          = azurerm_public_ip.GatewayIP.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    }
}

resource "azurerm_virtual_network_gateway_connection" "Site2Site-Azure-AWS" {
    name                = "${var.ConnectionName}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"

    type                       = "IPsec"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.AWS.id

    shared_key = var.shared_key
    enable_bgp = true
}