resource "aws_route53_zone" "main_domain_zone" {
    name    = var.web_domain
    comment = "Managed by Terraform for ${var.project_name} application"
    tags = {
        Name = "${var.project_name}-DomainZone"
    }
}

resource "aws_acm_certificate" "web_app_cert_main_region" {
    domain_name         = var.web_domain
    subject_alternative_names = [var.subdomain_wildcard]
    validation_method   = "DNS"

    tags = {
        Name = "${var.project_name}-Cert-MainRegion"
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_acm_certificate" "web_app_cert_us_east_1" {
    provider            = aws.us_east_1
    domain_name         = var.web_domain
    subject_alternative_names = [var.subdomain_wildcard]
    validation_method   = "DNS"

    tags = {
        Name = "${var.project_name}-Cert-USEast1"
    }

    lifecycle {
        create_before_destroy = true
    }
}

# DNS records for ACM certificate validation (main region)
resource "aws_route53_record" "cert_validation_main_region" {
    for_each = {
        for dvo in aws_acm_certificate.web_app_cert_main_region.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            type   = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    zone_id = aws_route53_zone.main_domain_zone.zone_id
    name    = each.value.name
    type    = each.value.type
    ttl     = 60
    records = [each.value.record]
}

# DNS records for ACM certificate validation (us-east-1)
resource "aws_route53_record" "cert_validation_us_east_1" {
    for_each = {
        for dvo in aws_acm_certificate.web_app_cert_us_east_1.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            type   = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    zone_id = aws_route53_zone.main_domain_zone.zone_id
    name    = each.value.name
    type    = each.value.type
    ttl     = 60
    records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_main_region" {
    certificate_arn         = aws_acm_certificate.web_app_cert_main_region.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation_main_region : record.fqdn]
}

resource "aws_acm_certificate_validation" "cert_us_east_1" {
    provider = aws.us_east_1
    certificate_arn         = aws_acm_certificate.web_app_cert_us_east_1.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation_us_east_1 : record.fqdn]
}

# ALIAS record for root domain pointing to ALB
resource "aws_route53_record" "alb_record" {
    zone_id = aws_route53_zone.main_domain_zone.zone_id
    name    = var.web_domain
    type    = "A"

    alias {
        name                   = aws_lb.main.dns_name
        zone_id                = aws_lb.main.zone_id
        evaluate_target_health = true
    }
}

# ALIAS record for wildcard subdomain pointing to ALB
resource "aws_route53_record" "alb_wildcard_record" {
    zone_id = aws_route53_zone.main_domain_zone.zone_id
    name    = var.subdomain_wildcard
    type    = "A"

    alias {
        name                   = aws_lb.main.dns_name
        zone_id                = aws_lb.main.zone_id
        evaluate_target_health = true
    }
}
