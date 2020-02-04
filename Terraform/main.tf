  
provider "azurerm" {
  version = "=1.36.0"
}

terraform {
  backend "azurerm" {
  }
}

variable "app_name" {
  type = "string"
}

data "azurerm_resource_group" "rg" {
  name = "${var.app_name}"
  location = "East US"
}

resource "azurerm_sql_server" "sqlserver" {
  name                         = "${var.app_name}-sqlserver"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  location                     = "${data.azurerm_resource_group.rg.location}"
  version                      = "12.0"
  administrator_login          = "nsadmin"
  administrator_login_password = "NewSignature2020"

  tags = {
    environment = "dev"
  }

}

resource "azurerm_app_service_plan" "app_plan" {
  name                = "${var.app_name}-appserviceplan"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "appsvc" {
  name                = "${var.app_name}-app-service"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  app_service_plan_id = "${azurerm_app_service_plan.app_plan.id}"

  site_config {
    dotnet_framework_version = "v4.0"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.app_name}-appinsights"
  location            = "East US"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  application_type    = "web"
}

resource "azurerm_redis_cache" "redis" {
  name                = "${var.app_name}-cache"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {}
}