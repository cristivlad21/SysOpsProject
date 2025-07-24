# --- CloudFront (CDN for Images and Application) ---

resource "aws_cloudfront_origin_access_identity" "s3_oai" {
    comment = "OAI for S3 bucket access via CloudFront"
}


# Cache policy for web application content (index.html, style.css, script.js)
# These are static files and can be cached aggressively.
resource "aws_cloudfront_cache_policy" "webapp_static_cache_policy" {
    name          = "${var.project_name}-WebAppStaticCachePolicy"
    comment       = "Policy for static web app content (HTML, CSS, JS) from ALB"
    default_ttl   = 86400    # Cache for 24 hours
    max_ttl       = 31536000 # Cache for 1 year (or longer, depends on update frequency)
    min_ttl       = 0

    parameters_in_cache_key_and_forwarded_to_origin {
        cookies_config {
            cookie_behavior = "none"
        }
        headers_config {
            header_behavior = "none"
        }
        query_strings_config {
            query_string_behavior = "none"
        }
    }
}

# Cache policy for images (very aggressive)
resource "aws_cloudfront_cache_policy" "images_cache_policy" {
    name          = "${var.project_name}-ImagesCachePolicy"
    comment       = "Policy for static images from S3"
    default_ttl   = 86400    # 24 hours
    max_ttl       = 31536000 # 1 year
    min_ttl       = 0

    parameters_in_cache_key_and_forwarded_to_origin {
        cookies_config {
            cookie_behavior = "none"
        }
        headers_config {
            header_behavior = "none"
        }
        query_strings_config {
            query_string_behavior = "none"
        }
    }
}


resource "aws_cloudfront_distribution" "s3_distribution" {
    origin {
        domain_name = aws_s3_bucket.images_bucket.bucket_regional_domain_name
        origin_id   = "S3-Images-Origin"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
        }
    }

    origin {
        domain_name = aws_lb.main.dns_name
        origin_id   = "ALB-Web-App-Origin"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "match-viewer" # Recommended: "https-only" if ALB is HTTPS
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    enabled             = true
    is_ipv6_enabled     = true
    comment             = "CloudFront distribution for Bamboo Slideshow"
    default_root_object = "index.html"

    aliases = [var.web_domain, var.subdomain_wildcard]

    default_cache_behavior {
        allowed_methods        = ["GET", "HEAD", "OPTIONS"]
        cached_methods         = ["GET", "HEAD"]
        target_origin_id       = "ALB-Web-App-Origin"
        cache_policy_id        = aws_cloudfront_cache_policy.webapp_static_cache_policy.id # Apply cache policy for static web app
        viewer_protocol_policy = "redirect-to-https"
    }

    ordered_cache_behavior {
        path_pattern         = "/images/*"  
        allowed_methods      = ["GET", "HEAD"]
        cached_methods       = ["GET", "HEAD"]
        target_origin_id     = "S3-Images-Origin"
        cache_policy_id      = aws_cloudfront_cache_policy.images_cache_policy.id
        viewer_protocol_policy = "redirect-to-https"
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        # MAJOR CORRECTION: Must use the certificate from us-east-1!
        acm_certificate_arn      = aws_acm_certificate.web_app_cert_us_east_1.arn # <--- THIS IS THE KEY MODIFICATION
        ssl_support_method       = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    tags = {
        Name = "${var.project_name}-CloudFront"
    }
}