provider "aws" {
    region = var.aws_region
}

provider "aws" {
    alias  = "us_east_1"
    region = "us-east-1"
}

terraform {
    backend "s3" {
        bucket  = "aws-bamboo-slideshow-bucket-configuration"
        key     = "bamboo-slideshow/terraform.tfstate"
        region  = "us-east-1"
        encrypt = true
    }
}
