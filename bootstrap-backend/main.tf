provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "backend" {
  bucket = "aws-bamboo-slideshow-bucket-configuration"
  force_destroy = true
}