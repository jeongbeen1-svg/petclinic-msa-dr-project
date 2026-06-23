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

# CloudFront - DNS
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

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront - S3
resource "aws_cloudfront_distribution" "s3_dist" {
  origin {
    domain_name              = "www.ajean.shop.s3.ap-northeast-2.amazonaws.com"
    origin_id                = "S3-www.ajean.shop"

    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    
    s3_origin_config {
      origin_access_identity = "" 
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-www.ajean.shop"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    viewer_protocol_policy = "redirect-to-https" # HTTP 접속 시 HTTPS로 강제 리다이렉트
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 기본 인증서 사용 (개인 도메인 연결 시 ACM 인증서 ID로 교체 필요)
  }
}

# AWS 리소스 상태 확인(Health Check) 생성
resource "aws_route53_health_check" "aws_service" {
  fqdn              = aws_cloudfront_distribution.distribution.domain_name
  type              = "HTTPS"
  port              = 443
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "30"
}

# Primary 레코드 (CloudFront -> ALB)
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    # 테스트용으로 false 처리
    evaluate_target_health = false
  }

  set_identifier  = "aws-primary"
  health_check_id = aws_route53_health_check.aws_service.id
  
  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Secondary 레코드 (CloudFront -> S3)
resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.ajean.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_dist.domain_name
    zone_id                = aws_cloudfront_distribution.s3_dist.hosted_zone_id # CloudFront 고유 Zone ID 자동 참조
    evaluate_target_health = false
  }

  set_identifier  = "azure-secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }
}