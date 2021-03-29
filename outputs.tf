output "MV-0-Public-IP" {
  value = aws_instance.cinegy-mv[0].public_ip
}

output "MV-0" {
  value = aws_instance.cinegy-mv[0]
}
