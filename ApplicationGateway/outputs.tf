output "application_gateway_monitor_metric" {
  description = "Salidas para todas las alertas de monitoreo, agrupadas por instancia de Application Gateway y métrica"
  value = {
    for key in keys(var.application_gateways) : key => {
      unhealthy_host_count = {
        id   = azurerm_monitor_metric_alert.unhealthy_host_count[key].id
        name = azurerm_monitor_metric_alert.unhealthy_host_count[key].name
      }

      failed_requests = {
        id   = azurerm_monitor_metric_alert.failed_requests[key].id
        name = azurerm_monitor_metric_alert.failed_requests[key].name
      }

      backend_connect_time = {
        id   = azurerm_monitor_metric_alert.backend_connect_time[key].id
        name = azurerm_monitor_metric_alert.backend_connect_time[key].name
      }
    }
  }
}
