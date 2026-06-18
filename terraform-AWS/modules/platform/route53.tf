# ACR 인증서 생성 및 요청
# resource "aws_acm_certificate" "cert" {
#   domain_name       = "ajean.com"
#   validation_method = "DNS" # DNS 방식을 권장합니다.

#   tags = {
#     Name = "my-certificate"
#   }
# }

# # 인증서 검증을 위한 DNS 레코드 생성
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   zone_id = data.aws_route53_zone.zone.zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.record]
#   ttl     = 60
# }

# # 검증 완료 대기 (이 리소스가 있어야 인증서가 발급될 때까지 테라폼이 기다림)
# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

resource "aws_route53_zone" "main" {
  name = "ajean.shop"
}

# AWS 리소스 상태 확인(Health Check) 생성
resource "aws_route53_health_check" "aws_service" {
  fqdn              = "www.${data.aws_route53_zone.selected.name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
}

# Primary 레코드 (AWS)
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = 60
  records = ["1.1.1.1"] # AWS 리소스 IP

  weighted_routing_policy {
    weight = 100
  }

  set_identifier = "aws-primary"
  # 가중치 라우팅의 경우 helty한 리소스들 사이에서 가중치 비율 계산됨 (장애 조치 효과까지 가능)
  health_check_id = aws_route53_health_check.aws_service.id
}

# Secondary 레코드 (Azure)
resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = 60
  records = ["2.2.2.2"] # Azure 리소스 IP

  weighted_routing_policy {
    weight = 0
  }

  set_identifier = "azure-secondary"
}