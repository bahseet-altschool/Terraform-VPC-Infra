output "fronted_ip" {
  description = "Frontend Public IP address: "
  value = aws_instance.frontend_web.public_ip
}

output "bastion_host_ip" {
  description = "Bastion Host Public IP address: "
  value = aws_instance.bastion_host.public_ip
}

output "server_api_ip" {
  description = "Server Private IP address: "
  value = aws_instance.server_api.private_ip
}