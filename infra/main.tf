terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Remote state is configured by the pipeline with -backend-config flags.
  # Locally, initialise with `terraform init -backend=false` (the
  # "Infra: init" task does this).
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

variable "app_name" {
  description = "Short application name used in every resource name"
  type        = string
  default     = "wealth-accounts"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "canadaeast"
}

variable "owner" {
  description = "Team that owns these resources, used for cost allocation"
  type        = string
  default     = "platform-team"
}

variable "transfer_limit" {
  description = "Per-transfer limit in CAD passed to the API as TRANSFER_LIMIT"
  type        = number
  default     = 10000
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"

  tags = {
    app         = var.app_name
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_service_plan" "main" {
  name                = "plan-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
}

resource "azurerm_linux_web_app" "api" {
  name                = "app-${local.name_prefix}-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = local.tags

  site_config {
    always_on           = true
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    health_check_path   = "/api/health"
    app_command_line    = "node app/server.js"

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    TRANSFER_LIMIT = tostring(var.transfer_limit)
  }
}

output "api_hostname" {
  description = "Default hostname of the accounts API"
  value       = azurerm_linux_web_app.api.default_hostname
}

output "api_app_name" {
  description = "Web app name, used by the pipeline to deploy the code"
  value       = azurerm_linux_web_app.api.name
}

output "resource_group_name" {
  description = "Resource group that holds the web app"
  value       = azurerm_resource_group.main.name
}
