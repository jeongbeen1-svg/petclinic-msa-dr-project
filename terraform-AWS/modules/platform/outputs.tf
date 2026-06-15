output "rds_endpoint" {
  value = aws_db_instance.petclinic_db.endpoint
}

output "rds_address" {
  value = aws_db_instance.petclinic_db.address
}

output "rds_port" {
  value = aws_db_instance.petclinic_db.port
}

output "rds_database_name" {
  value = aws_db_instance.petclinic_db.db_name
}

output "rds_username" {
  value = aws_db_instance.petclinic_db.username
}

output "dms_replication_instance_arn" {
  value = aws_dms_replication_instance.dms_instance.replication_instance_arn
}

output "dms_source_endpoint_arn" {
  value = aws_dms_endpoint.source.endpoint_arn
}

output "dms_target_azure_fqdn_endpoint_arn" {
  value = aws_dms_endpoint.target.endpoint_arn
}

output "dms_failback_source_azure_endpoint_arn" {
  value = aws_dms_endpoint.failback_source_azure.endpoint_arn
}

output "dms_failback_target_rds_endpoint_arn" {
  value = aws_dms_endpoint.failback_target_rds.endpoint_arn
}

output "dms_failback_azure_aws_task_arn" {
  value = aws_dms_replication_task.failback_azure_aws_task.replication_task_arn
}
