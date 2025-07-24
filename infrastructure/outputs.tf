output "s3_images_bucket_name" {
  description = "The name of the S3 bucket for images."
  value       = aws_s3_bucket.images_bucket.bucket
}

output "alb_dns_name" {
  description = "DNS Name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "website_url" {
  description = "The web application's URL via CloudFront."
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "private_ssh_key_path" {
  description = "Local path to the private SSH key."
  value       = local_file.private_key.filename
  sensitive   = true # Marked as sensitive to avoid exposure in logs
}

output "route53_nameservers" {
  description = "Route 53 nameservers to update at GoDaddy"
  value       = aws_route53_zone.main_domain_zone.name_servers
}
