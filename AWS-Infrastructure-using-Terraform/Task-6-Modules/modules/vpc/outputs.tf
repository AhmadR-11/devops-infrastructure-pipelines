# Requirement:
# • The module must output: vpc_id, public_subnet_ids, private_subnet_ids, and nat_gateway_id.

output "vpc_id" {
  value = aws_vpc.this.id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}
