# Requirement:
# • Create a modules/security/ module for Security Groups that accepts vpc_id and
# environment, and outputs web_sg_id and db_sg_id.

output "web_sg_id" {
  value = aws_security_group.web.id
}
output "db_sg_id" {
  value = aws_security_group.db.id
}
