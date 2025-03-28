output "ansible_controller_ip" {
  value = aws_instance.ansible_controller.public_ip
  description = "The public IP of the Ansible Controller"
}

output "jenkins_master_ip" {
  value = aws_instance.jenkins_master.public_ip
  description = "The public IP of the Jenkins Master"
}

output "jenkins_agent_ip" {
  value = aws_instance.jenkins_agent.public_ip
  description = "The public IP of the Jenkins Agent"
}
