# ホストゾーンのデータソース定義
data "aws_route53_zone" "test-system-dev" {
  name = "test-system-dev.link"
}

# ホストゾーンリソースの定義
resource "aws_route53_zone" "test-system-dev-rt53zone" {
  name = "test.test-system-dev.link"
}

# DNSレコードの定義
resource "aws_route53_record" "test-system-dev-rt53record" {
  zone_id = data.aws_route53_zone.test-system-dev.zone_id
  name    = data.aws_route53_zone.test-system-dev.name
  type    = "A"

  alias {
    name                   = aws_lb.test-system-dev-alb.dns_name
    zone_id                = aws_lb.test-system-dev-alb.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.test-system-dev-rt53record.name
}

# SSL証明書作成
resource "aws_acm_certificate" "test-system-dev-acm-certificate" {
  domain_name               = aws_route53_record.test-system-dev-rt53record.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# SSL証明書の検証用DNSレコードの定義
resource "aws_route53_record" "test-system-dev-acm-rt53record" {
  for_each = {
    for dvo in aws_acm_certificate.test-system-dev-acm-certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  zone_id = data.aws_route53_zone.test-system-dev.id
  ttl     = 60
}

# SSL証明書検証完了まで待機
resource "aws_acm_certificate_validation" "test-system-dev-acm-validation" {
  certificate_arn = aws_acm_certificate.test-system-dev-acm-certificate.arn
  validation_record_fqdns = [
    for record in aws_route53_record.test-system-dev-acm-rt53record : record.fqdn
  ]
}