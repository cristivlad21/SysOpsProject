resource "aws_security_group" "alb_sg" {
    name        = "${var.project_name}-ALB-SG"
    description = "Allows HTTP/HTTPS traffic to ALB."
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-ALB-SG"
    }
}

resource "aws_security_group" "ec2_sg" {
    name        = "${var.project_name}-EC2-SG"
    description = "Allows HTTP traffic from ALB and SSH from local network."
    vpc_id      = aws_vpc.main.id

    # Restrict HTTP access to traffic from the ALB only
    ingress {
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        security_groups  = [aws_security_group.alb_sg.id]
    }

    # WARNING: For production, restrict SSH access to trusted IPs only
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-EC2-SG"
    }
}
