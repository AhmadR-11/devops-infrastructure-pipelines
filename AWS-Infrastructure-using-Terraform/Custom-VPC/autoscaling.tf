#############################################################
# Task 4: Auto Scaling Group + CloudWatch Alarms
#
# What this file provisions:
# - ASG across both public subnets
# - Scale-out policy (+1) with 120s cooldown
# - Scale-in policy (-1) with 120s cooldown
# - CPU CloudWatch alarms for >= 60% and <= 20%
# - Outputs for easy demo/deliverables
#############################################################

resource "aws_autoscaling_group" "web_asg" {
  name = "skillswap-web-asg"

  # Requirement: span both public subnets.
  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  # Requirement: capacity boundaries and default desired state.
  min_size         = 1
  max_size         = 3
  # Requirement:
  # • Scale the ASG desired_capacity to 2 manually using terraform apply.
  desired_capacity = 2

  # Launch instances from the Task 4 launch template.
  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = "$Latest" # Always use most recent LT version.
  }

  # Requirement: Name tag must propagate to EC2 instances.
  tag {
    key                 = "Name"
    value               = "ASG-Web-Server"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_scale_out" {
  name                   = "skillswap-scale-out"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "SimpleScaling"

  # Requirement: ChangeInCapacity + increment by 1.
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown           = 120 # Requirement: avoid rapid oscillation.
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_scale_out" {
  alarm_name          = "skillswap-cpu-high-scale-out"
  alarm_description   = "Scale out when ASG average CPU >= 60% for 2x60s periods."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  # Trigger scale-out policy when alarm enters ALARM state.
  alarm_actions = [aws_autoscaling_policy.web_scale_out.arn]
}

resource "aws_autoscaling_policy" "web_scale_in" {
  name                   = "skillswap-scale-in"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "SimpleScaling"

  # Requirement: decrement by 1 with 120s cooldown.
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown           = 120
}

resource "aws_cloudwatch_metric_alarm" "cpu_low_scale_in" {
  alarm_name          = "skillswap-cpu-low-scale-in"
  alarm_description   = "Scale in when ASG average CPU <= 20% for 2x60s periods."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  # Trigger scale-in policy when alarm enters ALARM state.
  alarm_actions = [aws_autoscaling_policy.web_scale_in.arn]
}

#############################################################
# Outputs for Task 4 Deliverables
#############################################################

output "asg_name" {
  description = "Auto Scaling Group name for activity history verification."
  value       = aws_autoscaling_group.web_asg.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN."
  value       = aws_autoscaling_group.web_asg.arn
}

output "scale_out_policy_arn" {
  description = "Scale-out policy ARN triggered by high CPU alarm."
  value       = aws_autoscaling_policy.web_scale_out.arn
}

output "scale_in_policy_arn" {
  description = "Scale-in policy ARN triggered by low CPU alarm."
  value       = aws_autoscaling_policy.web_scale_in.arn
}

output "cpu_high_alarm_name" {
  description = "CloudWatch alarm name for scale-out trigger."
  value       = aws_cloudwatch_metric_alarm.cpu_high_scale_out.alarm_name
}

output "cpu_low_alarm_name" {
  description = "CloudWatch alarm name for scale-in trigger."
  value       = aws_cloudwatch_metric_alarm.cpu_low_scale_in.alarm_name
}

output "asg_console_path" {
  description = "AWS Console path to verify ASG activity history."
  value       = "EC2 Console -> Auto Scaling Groups -> ${aws_autoscaling_group.web_asg.name} -> Activity"
}

output "cloudwatch_alarms_console_path" {
  description = "AWS Console path to verify both CPU alarms."
  value       = "CloudWatch Console -> Alarms -> All alarms -> skillswap-cpu-high-scale-out / skillswap-cpu-low-scale-in"
}
