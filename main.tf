terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.51.0"
      
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  # backend "azurerm" {
  #   storage_account_name = "stdmpconflandingdev"
  #   container_name       = "devops"
  #   key                  = "tf/terraform.tfstate"
  #   client_id            = "xxxx"
  #   client_secret        = "xxxx"
  #   tenant_id            = "xxxx"
  #   subscription_id      = "xxxxx"
  # }
}
provider "confluent" {


  kafka_id ="lkc-xxxx"
  kafka_rest_endpoint = "https://lkc-xxx.xxx.westus2.azure.confluent.cloud:443"
  kafka_api_key    = "XXXX"
  kafka_api_secret = "XXXX"
  cloud_api_key  = "XXX"
  cloud_api_secret = "XXXX"
}
  
data "confluent_environment" "Azure-DMP-NonProd" {
  id = "env-xxxx"
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AWS"
  region  = "us-east-2"
  package = "ESSENTIALS"
}

data "confluent_schema_registry_cluster" "Azure-DMP-NonProd-SR" {
  id = "lsrc-xxxx"
  environment {
    id = "env-xxxx"
  }
}

data "confluent_kafka_cluster" "Azure-DMP-NonProd-CC" {
  id = "lkc-xxx"
  environment {
    id = "env-xxx"
  }
}

// 'app-manager' service account is required in this configuration to create 'orders' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}
resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id
    api_version = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.api_version
    kind        = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.kind

    environment {
      id = data.confluent_environment.Azure-DMP-NonProd.id
    }
  }
}


resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id
  }
  topic_name    = "orders"
  rest_endpoint = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.rest_endpoint
}
resource "confluent_kafka_topic" "mckesson_orders" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id
  }
  topic_name    = "mckesson_orders"
  rest_endpoint = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.rest_endpoint
}


resource "confluent_kafka_topic" "mckesson_orders_completed" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id
  }
  topic_name    = "mckesson_orders_completed"
  rest_endpoint = data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.rest_endpoint
}



resource "confluent_role_binding" "app-manager-order-developermanage" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "DeveloperManage"
  #crn_pattern = "${data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.rbac_crn}/kafka=${data.confluent_kafka_cluster.Azure-DMP-NonProd.id}/topic=${confluent_kafka_topic.orders.topic_name}"
  crn_pattern = "${data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.rbac_crn}/kafka=${data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}