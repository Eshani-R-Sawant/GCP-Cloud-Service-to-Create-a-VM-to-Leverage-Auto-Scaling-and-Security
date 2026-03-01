#!/bin/bash
# Update and install required packages
apt-get update
apt-get install -y apache2 stress
# Create a basic landing page identifying the host
echo "<h1>Scalable Web Server: $(hostname)</h1>" > /var/www/html/index.html
# Ensure Apache starts on boot
systemctl enable apache2
systemctl start apache2
