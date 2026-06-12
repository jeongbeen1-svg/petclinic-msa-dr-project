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
