# Data source for latest Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux_2_x86" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

# Data source for latest Amazon Linux 2 AMI (arm64)
data "aws_ami" "amazon_linux_2_arm" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-arm64-gp2"]
    }

    filter {
        name   = "architecture"
        values = ["arm64"]
    }
}

resource "tls_private_key" "main_ssh_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "main_key_pair" {
    key_name   = var.ssh_key_name
    public_key = tls_private_key.main_ssh_key.public_key_openssh

    tags = {
        Name = "${var.project_name}-SSH-Key"
    }
}

resource "local_file" "private_key" {
    content         = tls_private_key.main_ssh_key.private_key_pem
    filename        = "${path.module}/${var.ssh_key_name}.pem"
    file_permission = "0600"
}

resource "aws_iam_role" "ec2_instance_role" {
    name = "${var.project_name}-EC2-Role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            },
        ]
    })

    tags = {
        Name = "${var.project_name}-EC2-Role"
    }
}

# Policy for EC2 instances to access S3 bucket
resource "aws_iam_role_policy" "s3_access_policy" {
    name = "${var.project_name}-S3-Access-Policy"
    role = aws_iam_role.ec2_instance_role.id

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          Resource = [
            aws_s3_bucket.images_bucket.arn,
            "${aws_s3_bucket.images_bucket.arn}/*"
          ]
        }
      ]
    })
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.project_name}-EC2-Profile"
    role = aws_iam_role.ec2_instance_role.name
}

resource "aws_launch_template" "webapp_x86" {
    name_prefix   = "${var.project_name}-LT-X86-"
    image_id      = data.aws_ami.amazon_linux_2_x86.id
    key_name      = aws_key_pair.main_key_pair.key_name
    instance_type = "t3.nano"

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_profile.name
    }

    network_interfaces {
        associate_public_ip_address = false
        security_groups             = [aws_security_group.ec2_sg.id]
    }

    user_data = base64encode(templatefile("${path.module}/install_webapp.sh", {
        CLOUDFRONT_IMAGES_BASE_URL = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/images/"
    }))

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name        = "${var.project_name}-EC2-Instance-X86"
            Environment = "Production"
        }
    }
    tag_specifications {
        resource_type = "volume"
        tags = {
            Name        = "${var.project_name}-EC2-Volume-X86"
            Environment = "Production"
        }
    }
}

resource "aws_launch_template" "webapp_arm" {
    name_prefix   = "${var.project_name}-LT-ARM-"
    image_id      = data.aws_ami.amazon_linux_2_arm.id
    key_name      = aws_key_pair.main_key_pair.key_name
    instance_type = "t4g.nano"

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_profile.name
    }

    network_interfaces {
        associate_public_ip_address = false
        security_groups             = [aws_security_group.ec2_sg.id]
    }

    user_data = base64encode(templatefile("${path.module}/install_webapp.sh", {
        CLOUDFRONT_IMAGES_BASE_URL = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/images/"
    }))

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name        = "${var.project_name}-EC2-Instance-ARM"
            Environment = "Production"
        }
    }
    tag_specifications {
        resource_type = "volume"
        tags = {
            Name        = "${var.project_name}-EC2-Volume-ARM"
            Environment = "Production"
        }
    }
}

# Mixed instance policy for cost optimization and flexibility
resource "aws_autoscaling_group" "webapp" {
    name                      = "${var.project_name}-ASG"
    min_size                  = var.min_size
    max_size                  = var.max_size
    desired_capacity          = var.desired_capacity
    vpc_zone_identifier       = [for subnet in aws_subnet.private : subnet.id]
    target_group_arns         = [aws_lb_target_group.main.arn]
    health_check_type         = "ELB"
    health_check_grace_period = 300

    mixed_instances_policy {
        instances_distribution {
            on_demand_base_capacity                  = 0
            on_demand_percentage_above_base_capacity = 0
            spot_allocation_strategy                 = "capacity-optimized"
        }

        launch_template {
            launch_template_specification {
                launch_template_id = aws_launch_template.webapp_arm.id
                version            = "$Latest"
            }
            override {
                instance_type = "t3a.nano"
                launch_template_specification {
                    launch_template_id = aws_launch_template.webapp_x86.id
                    version            = "$Latest"
                }
            }
            override {
                instance_type = "t3.nano"
                launch_template_specification {
                    launch_template_id = aws_launch_template.webapp_x86.id
                    version            = "$Latest"
                }
            }
            override {
                instance_type = "t2.nano"
                launch_template_specification {
                    launch_template_id = aws_launch_template.webapp_x86.id
                    version            = "$Latest"
                }
            }
        }
    }

    tag {
        key                 = "Name"
        value               = "${var.project_name}-ASG"
        propagate_at_launch = false
    }
}

# Target tracking scaling policy based on average CPU utilization
resource "aws_autoscaling_policy" "cpu_scale_out" {
    name                   = "${var.project_name}-CPU-ScaleOut"
    autoscaling_group_name = aws_autoscaling_group.webapp.name
    policy_type            = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
    estimated_instance_warmup = 300
}

resource "aws_autoscaling_policy" "cpu_scale_in" {
    name                   = "${var.project_name}-CPU-ScaleIn"
    autoscaling_group_name = aws_autoscaling_group.webapp.name
    policy_type            = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 30.0
        disable_scale_in = false
    }
    estimated_instance_warmup = 300
}

# Scheduled scaling actions for business hours and off-hours
resource "aws_autoscaling_schedule" "scale_up_weekday" {
    autoscaling_group_name = aws_autoscaling_group.webapp.name
    scheduled_action_name  = "${var.project_name}-scale-up-daily"
    recurrence             = "30 5 * * *"
    min_size               = var.min_size
    max_size               = var.max_size
    desired_capacity       = var.desired_capacity
}

resource "aws_autoscaling_schedule" "scale_down_night" {
    autoscaling_group_name = aws_autoscaling_group.webapp.name
    scheduled_action_name  = "${var.project_name}-scale-down-daily"
    recurrence             = "30 20 * * *"
    min_size               = 0
    max_size               = 0
    desired_capacity       = 0
}
