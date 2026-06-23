# ACR 인증서 생성 및 요청 (us)
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
resource "aws_route53_record" "cert_validation_us" {
  provider = aws.us_east_1
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo
  }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.ajean.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "cert_us" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation_us : r.fqdn]
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["www.ajean.shop"]

  # Origin 설정 (내부 통신용 주소여야 함)
  origin {
    domain_name = local.ingress_dns_name
    origin_id   = "my-app-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
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
    acm_certificate_arn      = aws_acm_certificate_validation.cert_us.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # 차단 정책 (Geo Restriction)
  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  depends_on = [aws_acm_certificate_validation.cert_us]
}

# AWS 리소스 상태 확인(Health Check) 생성
resource "aws_route53_health_check" "aws_service" {
  fqdn              = "www.${data.aws_route53_zone.ajean.name}"
  type              = "HTTPS"
  port              = 443
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"
}

# Primary 레코드 (AWS)
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 60
  records = [aws_cloudfront_distribution.distribution.domain_name]

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "aws-primary"
  health_check_id = aws_route53_health_check.aws_service.id
}

# Secondary 레코드 (정적 웹 호스팅 -> 장애 복구 완료 후 Azure)
resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 60
  records = ["tf-core-error.s3-website.ap-northeast-2.amazonaws.com"]

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "azure-secondary"
}