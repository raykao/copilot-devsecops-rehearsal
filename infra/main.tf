terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
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
