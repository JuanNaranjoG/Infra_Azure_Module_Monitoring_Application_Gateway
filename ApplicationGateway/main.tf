####################################################################################################
# Alerta: Backends no saludables detectados por el health probe
# Dispara cuando al menos un backend es marcado como no saludable
####################################################################################################
resource "azurerm_monitor_metric_alert" "unhealthy_host_count" {
  for_each = var.application_gateways

  name                = "${var.project}-${each.key}-unhealthy-host-count-${var.bdo_environment}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.id]
  description         = "Alerta de backends no saludables del Azure Application Gateway"
  severity            = var.metric_severity["unhealthy_host_count"]
  frequency           = var.frequency
  window_size         = var.window_size

  criteria {
    metric_namespace = local.namespace
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.thresholds.unhealthy_host_count
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    {
      Name              = "${var.project}-${each.key}-unhealthy-host-count-${var.bdo_environment}"
      bdo-resource-type = "global"
    },
    var.resource_aditional_tags != null ? var.resource_aditional_tags : {},
    var.resource_tags
  )
}

####################################################################################################
# Alerta: Solicitudes fallidas del Application Gateway
# Dispara cuando el número de solicitudes que el gateway no pudo servir supera el umbral
####################################################################################################
resource "azurerm_monitor_metric_alert" "failed_requests" {
  for_each = var.application_gateways

  name                = "${var.project}-${each.key}-failed-requests-${var.bdo_environment}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.id]
  description         = "Alerta de solicitudes fallidas del Azure Application Gateway"
  severity            = var.metric_severity["failed_requests"]
  frequency           = var.frequency
  window_size         = var.window_size

  criteria {
    metric_namespace = local.namespace
    metric_name      = "FailedRequests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.thresholds.failed_requests
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    {
      Name              = "${var.project}-${each.key}-failed-requests-${var.bdo_environment}"
      bdo-resource-type = "global"
    },
    var.resource_aditional_tags != null ? var.resource_aditional_tags : {},
    var.resource_tags
  )
}

####################################################################################################
# Alerta: Tiempo de conexión TCP hacia los backends
# Monitorea el tiempo promedio que tarda en establecerse la conexión TCP con los backends (ms)
####################################################################################################
resource "azurerm_monitor_metric_alert" "backend_connect_time" {
  for_each = var.application_gateways

  name                = "${var.project}-${each.key}-backend-connect-time-${var.bdo_environment}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.id]
  description         = "Alerta de tiempo de conexión TCP hacia backends del Azure Application Gateway"
  severity            = var.metric_severity["backend_connect_time"]
  frequency           = var.frequency
  window_size         = var.window_size

  criteria {
    metric_namespace = local.namespace
    metric_name      = "BackendConnectTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.thresholds.backend_connect_time
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    {
      Name              = "${var.project}-${each.key}-backend-connect-time-${var.bdo_environment}"
      bdo-resource-type = "global"
    },
    var.resource_aditional_tags != null ? var.resource_aditional_tags : {},
    var.resource_tags
  )
}
