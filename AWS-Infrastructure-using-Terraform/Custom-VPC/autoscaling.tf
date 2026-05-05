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

resource "aws_autoscaling_group" "asg_blue" {
  name = "skillswap-asg-blue"

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG-Blue"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_green" {
  name = "skillswap-asg-green"

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG-Green"
    propagate_at_launch = true
  }
}

# Note: Alarms are attached to the Blue ASG for this assignment setup.
# In a real environment, you would duplicate these for the Green ASG.
resource "aws_autoscaling_policy" "web_scale_out" {
  name                   = "skillswap-scale-out"
  autoscaling_group_name = aws_autoscaling_group.asg_blue.name
  policy_type            = "SimpleScaling"

  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown           = 120
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
    AutoScalingGroupName = aws_autoscaling_group.asg_blue.name
  }

  alarm_actions = [aws_autoscaling_policy.web_scale_out.arn]
}

resource "aws_autoscaling_policy" "web_scale_in" {
  name                   = "skillswap-scale-in"
  autoscaling_group_name = aws_autoscaling_group.asg_blue.name
  policy_type            = "SimpleScaling"

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
    AutoScalingGroupName = aws_autoscaling_group.asg_blue.name
  }

  alarm_actions = [aws_autoscaling_policy.web_scale_in.arn]
}

#############################################################
# Outputs for Task 4 Deliverables
#############################################################

output "asg_blue_name" {
  description = "Auto Scaling Group Blue name"
  value       = aws_autoscaling_group.asg_blue.name
}

output "asg_green_name" {
  description = "Auto Scaling Group Green name"
  value       = aws_autoscaling_group.asg_green.name
}
