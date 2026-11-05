output "Public_IP" {
     value = aws_instance.main.public_ip
 }

 output "Instance_ID" {
     value = aws_instance.main.id
 }

 output "Private_Key" {
     value = tls_private_key.main.private_key_pem
     sensitive = true
 }