output "VnetGateway_Name" {
    description = "Name of the provisioned VNet Gateway resource"
    value       = azurerm_virtual_network_gateway.VnetGateway.name
}