# ⚡ Azure Application Gateway Monitoring Module (Azure)

This Terraform module provisions **Azure Monitor metric alerts for Azure Application Gateway**.

It is designed as a reusable module that supports monitoring **multiple Application Gateway instances** using a single, unified variable, following the same design standards as other monitoring modules.

The module monitors **unhealthy backends, failed requests, and backend connection time** from the `Microsoft.Network/applicationGateways` namespace and sends notifications through an **Azure Monitor Action Group**.

---

### 🚀 Usage

```hcl
module "application_gateway_monitoring" {
  source = "git::git@github.com:bocc-principal/Infra_Azure_Module_Monitoring_Application_Gateway.git//ApplicationGateway?ref=1.0.0"

  application_gateways = {
    AppGatewayPrincipal = {
      id = azurerm_application_gateway.app_gateway_principal.id
    }

    # AppGatewaySecundario = {
    #   id = azurerm_application_gateway.app_gateway_secundario.id
    # }

    # Ejemplo con ID hardcodeado:
    # agw-gestion-prod = {
    #   id = "/subscriptions/3eba9cfb-6349-4491-b43c-2d3a76ded2a2/resourceGroups/RG-Monitoreo/providers/Microsoft.Network/applicationGateways/agw-gestion-prod"
    # }
  }

  resource_group_name = azurerm_resource_group.rg-monitoreo.name
  action_group_id     = azurerm_monitor_action_group.monitoring_ag.id
  project             = "Gestion_TI"
  bdo_environment     = "env"
  resource_tags       = module.tags.common-tags

  thresholds = {
    unhealthy_host_count  = 1     # Count — alerta si al menos 1 backend es marcado como no saludable
    failed_requests       = 50    # Count — alerta si el número de solicitudes fallidas supera 50
    backend_connect_time  = 5000  # ms — alerta si el tiempo promedio de conexión TCP supera 5000 ms
  }

  metric_severity = {
    unhealthy_host_count  = 0  # Critical
    failed_requests       = 1  # Error
    backend_connect_time  = 2  # Warning
  }
}
```

> 💡 **Note:** Only define the Application Gateway instances you want to monitor. The map key is used as an identifier in the name of each alert.

---

## 🔔 Action Group Configuration (Required)

```hcl
resource "azurerm_monitor_action_group" "monitoring_ag" {
  name                = "ag-monitoring-${var.project}"
  resource_group_name = var.resource_group_name
  short_name          = "mon-ag"

  email_receiver {
    name          = "correo1"
    email_address = "correo1@bancodeoccidente.com.co"
  }

  email_receiver {
    name          = "correo2"
    email_address = "correo2@bancodeoccidente.com.co"
  }
}
```

> 💡 **Note:** The Action Group must exist before applying this module. Pass its ID via the `action_group_id` variable.

---

### ✅ Requirements

| Name             | Version |
| ---------------- | ------- |
| Terraform        | >= 1.0  |
| AzureRM Provider | >= 3.0  |

---

### 📊 Monitored Metrics (Microsoft.Network/applicationGateways)

| Metric_Name          | Descripción                                                                  | metric_namespace                       | Operator           | Severity | Frequency | window_size | Aggregation | Threshold    |
| -------------------- | ---------------------------------------------------------------------------- | -------------------------------------- | ------------------ | -------- | --------- | ----------- | ----------- | ------------ |
| UnhealthyHostCount   | Backends marcados como no saludables por el health probe (Count).            | Microsoft.Network/applicationGateways  | GreaterThanOrEqual | 0        | PT5M      | PT5M        | Average     | >= 1         |
| FailedRequests       | Número de solicitudes que el gateway no pudo servir (Count).                 | Microsoft.Network/applicationGateways  | GreaterThan        | 1        | PT5M      | PT5M        | Total       | > 50         |
| BackendConnectTime   | Tiempo de conexión TCP hacia los backends (ms).                              | Microsoft.Network/applicationGateways  | GreaterThan        | 2        | PT5M      | PT5M        | Average     | > 5000 ms    |

---

### 🔔 Azure Monitor Alerts

#### 🚨 Unhealthy Host Count

Fires when at least one backend is marked as unhealthy by the health probe within the evaluation window. An unhealthy backend means the Application Gateway has stopped sending traffic to it, which can cause capacity reduction or service degradation.

- Metric: `UnhealthyHostCount`
- Unit: Count
- Aggregation: Average
- Operator: GreaterThanOrEqual
- Default threshold: **1** (`unhealthy_host_count = 1`)
- Default severity: **0 (Critical)**

> ⚠️ **Important:** Un backend no saludable indica que el health probe no está recibiendo respuestas esperadas. Verifique el estado de las instancias de backend, la configuración del health probe (ruta, protocolo, código de respuesta esperado) y la conectividad de red entre el gateway y los backends.

#### ❌ Failed Requests

Fires when the number of requests that the Application Gateway could not serve exceeds the threshold. This includes requests that failed due to backend errors, timeouts, or configuration issues.

- Metric: `FailedRequests`
- Unit: Count
- Aggregation: Total
- Operator: GreaterThan
- Default threshold: **50** (`failed_requests = 50`)
- Default severity: **1 (Error)**

> ⚠️ **Important:** Las solicitudes fallidas pueden deberse a backends no saludables, timeouts de respuesta, errores HTTP 5xx de los backends, o problemas de configuración en las reglas de enrutamiento. Revise los logs de acceso del Application Gateway para identificar el origen de los errores.

#### 🐢 Backend Connect Time

Monitors the average time it takes to establish a TCP connection between the Application Gateway and its backends. High connection times can indicate network latency, backend resource exhaustion, or connectivity issues.

- Metric: `BackendConnectTime`
- Unit: Milliseconds (ms)
- Aggregation: Average
- Operator: GreaterThan
- Default threshold: **5000 ms** (`backend_connect_time = 5000`)
- Default severity: **2 (Warning)**

> ⚠️ **Important:** El tiempo de conexión TCP elevado suele indicar latencia de red entre el gateway y los backends, saturación de recursos en los servidores backend, o problemas de configuración en los grupos de seguridad de red (NSG). Revise la latencia de red y el estado de los backends en el portal de Azure.

---

### ⚙️ Input Variables

#### Required

| Name                  | Type                                   | Description                                                                                                                                          |
| --------------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| application_gateways  | `map(object({ id = string }))`         | Map of Application Gateway instances to monitor. The key is used as an identifier in each alert name                                                 |
| resource_group_name   | `string`                               | Name of the resource group where the Application Gateway instances reside                                                                            |
| action_group_id       | `string`                               | ID of the Action Group used for sending notifications                                                                                                |
| metric_severity       | `map(number)`                          | Severity per metric (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose). Keys: `unhealthy_host_count`, `failed_requests`, `backend_connect_time` |
| project               | `string`                               | Project or initiative name                                                                                                                           |
| bdo_environment       | `string`                               | Resource environment (Dev, QA, Prod, etc.)                                                                                                           |

#### Optional

| Name                    | Type                                                                          | Default                    | Description                                    |
| ----------------------- | ----------------------------------------------------------------------------- | -------------------------- | ---------------------------------------------- |
| thresholds              | `object({ unhealthy_host_count, failed_requests, backend_connect_time })`     | See variables.tf           | Thresholds per metric                          |
| frequency               | `string`                                                                      | `PT5M`                     | Alert evaluation frequency                     |
| window_size             | `string`                                                                      | `PT5M`                     | Time window for evaluation                     |
| purpose                 | `string`                                                                      | `monitoring`               | Purpose of the resource                        |
| name_sevice             | `string`                                                                      | `Azure Application Gateway`| Name of the service being monitored            |
| resource_tags           | `map(string)`                                                                 | `{}`                       | Mandatory BdO / Aval tags                      |
| resource_aditional_tags | `map(string)`                                                                 | `{}`                       | Optional additional tags                       |

---

### 📤 Outputs

#### application_gateway_monitor_metric

Returns all alerts created by the module, grouped by Application Gateway instance and metric.

```hcl
application_gateway_monitor_metric = {
  AppGatewayPrincipal = {
    unhealthy_host_count = {
      id   = "/subscriptions/.../metricAlerts/Gestion_TI-AppGatewayPrincipal-unhealthy-host-count-prod"
      name = "Gestion_TI-AppGatewayPrincipal-unhealthy-host-count-prod"
    }
    failed_requests = {
      id   = "/subscriptions/.../metricAlerts/Gestion_TI-AppGatewayPrincipal-failed-requests-prod"
      name = "Gestion_TI-AppGatewayPrincipal-failed-requests-prod"
    }
    backend_connect_time = {
      id   = "/subscriptions/.../metricAlerts/Gestion_TI-AppGatewayPrincipal-backend-connect-time-prod"
      name = "Gestion_TI-AppGatewayPrincipal-backend-connect-time-prod"
    }
  }
}
```

---

### 🧠 Notes

- This module uses the namespace `Microsoft.Network/applicationGateways` compatible with all Application Gateway SKUs (Standard_v2, WAF_v2).
- `UnhealthyHostCount` uses `GreaterThanOrEqual` with threshold `1` — any unhealthy backend triggers the alert immediately.
- `FailedRequests` uses `Total` aggregation — counts all failed requests within the evaluation window.
- `BackendConnectTime` measures only the TCP connection establishment time to backends. It does not include request processing or response time.
- Severity must be between **0 (Critical)** and **4 (Verbose)**.
- The Action Group must exist beforehand — this module does not create it.
- Alerts are created using `for_each` per gateway instance, allowing each alert to be managed independently in the Terraform state.

---

### 📘 References

- Azure Monitor Supported Metrics for Application Gateway:
  https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-network-applicationgateways-metrics

- Monitoring Azure Application Gateway:
  https://learn.microsoft.com/en-us/azure/application-gateway/monitor-application-gateway

- Azure Application Gateway Metrics Reference:
  https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-metrics

- Azure Monitor Metric Alerts:
  https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-metric-overview

- AzureRM Provider – Monitor Metric Alert:
  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert

- AzureRM Provider – Application Gateway:
  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
