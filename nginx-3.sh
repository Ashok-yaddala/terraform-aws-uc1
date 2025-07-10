#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "Register! (Instance C)" | sudo tee /usr/share/nginx/html/register.html