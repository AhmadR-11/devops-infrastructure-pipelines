# Requirement:
# • The module should create the EC2 instance, output its public_ip and instance_id.

output "public_ip" {
  value = aws_instance.this.public_ip
}
output "instance_id" {
  value = aws_instance.this.id
}
