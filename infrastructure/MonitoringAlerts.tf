resource "aws_sns_topic" "alerts_topic" {
    name = "${var.project_name}-Alerts-Topic"
    tags = {
        Name = "${var.project_name}-Alerts-Topic"
    }
}

resource "aws_sns_topic_subscription" "email_subscription" {
    topic_arn = aws_sns_topic.alerts_topic.arn
    protocol  = "email"
    endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
    alarm_name          = "${var.project_name}-High-CPU-Utilization"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 75
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.webapp.name
    }
    alarm_description = "Monitors average CPU usage for the Auto Scaling group."
    alarm_actions     = [aws_sns_topic.alerts_topic.arn]
    ok_actions        = [aws_sns_topic.alerts_topic.arn]
    treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors_alarm" {
    alarm_name          = "${var.project_name}-ALB-HTTP-5xx-Errors"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "HTTPCode_Target_5XX_Count"
    namespace           = "AWS/ApplicationELB"
    period              = 60
    statistic           = "Sum"
    threshold           = 5
    dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.main.arn_suffix
    }
    alarm_description = "Triggers if the ALB reports 5xx errors from targets."
    alarm_actions     = [aws_sns_topic.alerts_topic.arn]
    ok_actions        = [aws_sns_topic.alerts_topic.arn]
    treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed_alarm" {
    alarm_name          = "${var.project_name}-EC2-Status-Check-Failed"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "StatusCheckFailed"
    namespace           = "AWS/EC2"
    period              = 60
    statistic           = "Maximum"
    threshold           = 1
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.webapp.name
    }
    alarm_description = "Triggers if an instance in the ASG fails the status check."
    alarm_actions     = [aws_sns_topic.alerts_topic.arn]
    ok_actions        = [aws_sns_topic.alerts_topic.arn]
    treat_missing_data = "notBreaching"
}
