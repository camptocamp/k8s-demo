resource "azuread_application" "this" {
  name       = var.application_name
  reply_urls = var.reply_urls

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  group_membership_claims = "ApplicationGroup"

  optional_claims {
    access_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
    id_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
  }
}

resource "random_password" "this" {
  length           = 34
  special          = true
  override_special = "-_~."
}

resource "azuread_application_password" "this" {
  application_object_id = azuread_application.this.id
  end_date              = "2299-12-30T23:00:00Z"
  value                 = random_password.this.result
}

resource "azuread_application_app_role" "this" {
  application_object_id = azuread_application.this.id
  allowed_member_types  = ["User"]
  description           = var.app_role_description
  display_name          = var.app_role_display_name
  is_enabled            = true
  value                 = var.app_role_name
}
