resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_prefix          = replace(local.cluster_name, "_", "-")

  private_cluster_enabled = false

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D2s_v3"
    vnet_subnet_id       = local.private_subnet_ids[0]
    node_count           = 1
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })
}
