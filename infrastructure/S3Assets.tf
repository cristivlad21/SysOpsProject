resource "aws_s3_bucket" "images_bucket" {
  bucket = var.s3_bucket_name   

  tags = {
    Name = "${var.project_name}-ImagesBucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "images_bucket_ownership_controls" {
  bucket = aws_s3_bucket.images_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "images_bucket_block" {
  bucket = aws_s3_bucket.images_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "images_bucket_policy" {
  bucket = aws_s3_bucket.images_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowCloudFrontOAI",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.s3_oai.id}"
        },
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.images_bucket.id}/images/*"
      }
    ]
  })
}

# Ensures images are uploaded only after bucket and related resources are ready
resource "null_resource" "upload_images_to_s3" {
  depends_on = [
    aws_s3_bucket.images_bucket,
    aws_s3_bucket_public_access_block.images_bucket_block,
    aws_s3_bucket_policy.images_bucket_policy,
    aws_s3_bucket_ownership_controls.images_bucket_ownership_controls
  ]
}

resource "aws_s3_object" "slideshow_images" {
  for_each     = fileset("${path.module}/images", "*.jpg")
  bucket       = aws_s3_bucket.images_bucket.id
  key          = "images/${each.value}"
  source       = "${path.module}/images/${each.value}"
  acl          = "private"
  content_type = "image/jpeg"   
}
