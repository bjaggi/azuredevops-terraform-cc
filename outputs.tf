output "resource-ids" {

  value = <<-EOT

  Environment ID:   ${data.confluent_environment.Azure-DMP-NonProd.id}

  Kafka Cluster ID: ${data.confluent_kafka_cluster.Azure-DMP-NonProd-CC.id}

  Kafka topic name: ${confluent_kafka_topic.orders.topic_name}

 

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):

  ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}

  
  EOT

 

  sensitive = true

}