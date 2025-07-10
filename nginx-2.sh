#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "Images! (Instance B)" | sudo tee /usr/share/nginx/html/image.html