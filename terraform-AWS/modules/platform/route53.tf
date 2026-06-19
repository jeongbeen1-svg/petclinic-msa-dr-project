resource "aws_route53_zone" "main" {
  name = "ajean.shop"
}

# AWS 리소스 상태 확인(Health Check) 생성
resource "aws_route53_health_check" "aws_service" {
  fqdn              = "www.${aws_route53_zone.main.name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
}

# Primary 레코드 (AWS)
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${aws_route53_zone.main.name}"
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
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${aws_route53_zone.main.name}"
  type    = "A"
  ttl     = 60
  records = ["2.2.2.2"] # Azure 리소스 IP

  weighted_routing_policy {
    weight = 0
  }

  set_identifier  = "azure-secondary"
  health_check_id = aws_route53_health_check.aws_service.id
}

# ACR 인증서 생성 및 요청
resource "aws_acm_certificate" "cert" {
  provider    = aws.us_east_1
  domain_name = "ajean.shop"
  # 인증서가 여러 도메인을 모두 포함하도록 설정
  subject_alternative_names = ["*.ajean.shop"]
  validation_method         = "DNS" # DNS 방식을 권장

  tags = {
    Name = "my-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 인증서 검증을 위한 DNS 레코드 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

# 검증 완료 대기 (이 리소스가 있어야 인증서가 발급될 때까지 테라폼이 기다림)
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["www.ajean.shop"]

  # Origin 설정 (Route 53에서 만든 도메인을 가리킴)
  origin {
    domain_name = "www.ajean.shop"
    origin_id   = "my-app-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 기본 캐시 동작
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my-app-origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  # 인증서 연결
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # 차단 정책 (Geo Restriction)
  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  depends_on = [aws_acm_certificate_validation.cert]
}