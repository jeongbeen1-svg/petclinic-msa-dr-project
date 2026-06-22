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

output "acm_certificate_arn" {
  description = "CloudFront 및 ALB에서 사용할 인증서 ARN"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}
