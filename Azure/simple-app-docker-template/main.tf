provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "simplerg" {
  name     = "terraform-group"
  location = var.location
  tags     = var.tags
}

resource "azurerm_application_insights" "ai" {
  name                = "terraform-ai"
  resource_group_name = azurerm_resource_group.simplerg.name
  location            = azurerm_resource_group.simplerg.location
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "terraform-app-svc-plan"
  resource_group_name = azurerm_resource_group.simplerg.name
  location            = azurerm_resource_group.simplerg.location
  kind                = var.appservice_plan_kind
  reserved            = true
  tags                = var.tags

  sku {
    tier = var.appservice_plan_tier
    size = var.appservice_plan_size
  }
}

resource "azurerm_app_service" "appservice" {
  name                = "simple-terraform-app"
  resource_group_name = azurerm_resource_group.simplerg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  location            = azurerm_resource_group.simplerg.location
  tags                = var.tags

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }

  site_config {
    always_on        = var.appservice_always_on
    linux_fx_version = "DOCKER|${var.appservice_docker_image}"
  }
}
