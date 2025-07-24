variable "project_name" {
    description = "Project name, used as a prefix for resources."
    type        = string
    default     = "BSS"
}

variable "aws_region" {
    description = "AWS region where resources will be created."
    type        = string
    default     = "eu-east-1"
}

variable "vpc_cidr_block" {
    description = "CIDR block for the VPC."
    type        = string
    default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for public subnets."
    type        = list(string)
    default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "List of CIDR blocks for private subnets."
    type        = list(string)
    default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ssh_key_name" {
    description = "Name of the SSH key to be used for EC2 instances."
    type        = string
    default     = "bamboo-slideshow-key"
}

variable "min_size" {
    description = "Minimum number of instances for the Auto Scaling Group."
    type        = number
    default     = 1
}

variable "max_size" {
    description = "Maximum number of instances for the Auto Scaling Group."
    type        = number
    default     = 3
}

variable "desired_capacity" {
    description = "Desired number of instances for the Auto Scaling Group at launch."
    type        = number
    default     = 1
}

variable "s3_bucket_name" {
    description = "Name of the bucket."
    type        = string
    default     = "bamboo-slideshow-images"
}

variable "web_domain" {
    description = "Main domain for the web application (e.g., example.com)."
    type        = string
    default     = "domain.info"
}

variable "subdomain_wildcard" {
    description = "Wildcard subdomain for the ACM certificate (e.g., *.example.com)."
    type        = string
    default     = "*.domain.info"
}

# Used for CloudWatch alert notifications. Ensure this is a valid email address.
variable "alert_email" {
    description = "Email address for CloudWatch alert notifications."
    type        = string
    default     = "THEEMAIL@MAIL.com"
}
