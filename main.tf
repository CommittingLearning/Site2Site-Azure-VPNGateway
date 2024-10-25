resource "azurerm_local_network_gateway" "AWS1" {
    name                = "${var.customer_gateway1}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP
    address_space       = [var.customerCIDR]

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.167.61"
    }
}

resource "azurerm_local_network_gateway" "AWS2" {
    name                = "${var.customer_gateway2}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    gateway_address     = var.customerIP
    address_space       = [var.customerCIDR]

    bgp_settings {
        asn = 65001
        bgp_peering_address = "169.254.78.237"
    }
}

resource "azurerm_public_ip" "GatewayIP1" {
    name                = "${var.GatewayIPName1}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"
    allocation_method   = "Static"
}

resource "azurerm_public_ip" "GatewayIP2" {
    name                = "${var.GatewayIPName2}_${var.environment}"
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

    active_active = true
    enable_bgp    = true
    sku           = var.gatewaysku

    ip_configuration {
        public_ip_address_id          = azurerm_public_ip.GatewayIP1.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    }

    ip_configuration {
        public_ip_address_id          = azurerm_public_ip.GatewayIP2.id
        private_ip_address_allocation = "Dynamic"
        subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    }
}

resource "azurerm_virtual_network_gateway_connection" "Site2Site-Azure-AWS1" {
    name                = "${var.ConnectionName1}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"

    type                       = "IPsec"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.AWS1.id

    shared_key = var.shared_key
    enable_bgp = true

    ipsec_policy {
        dh_group             = "DHGroup14"
        ike_encryption       = "AES256"
        ike_integrity        = "SHA256"
        ipsec_encryption     = "AES256"
        ipsec_integrity      = "SHA256"
        pfs_group            = "PFS2"
        sa_lifetime          = 3600
    }
}

# VPN Connection for Tunnel 2
resource "azurerm_virtual_network_gateway_connection" "Site2Site-Azure-AWS2" {
    name                = "${var.ConnectionName2}_${var.environment}"
    location            = var.location
    resource_group_name = "${var.rg_name}_${var.environment}"

    type                       = "IPsec"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.VnetGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.AWS2.id

    shared_key = var.shared_key
    enable_bgp = true

    ipsec_policy {
        dh_group             = "DHGroup14"
        ike_encryption       = "AES256"
        ike_integrity        = "SHA256"
        ipsec_encryption     = "AES256"
        ipsec_integrity      = "SHA256"
        pfs_group            = "PFS2"
        sa_lifetime          = 3600
    }
}