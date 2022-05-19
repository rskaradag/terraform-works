#!/bin/bash

yum update -y 
yum install python3 -y
pip3 install flask
cd /home/ec2-user
wget https://raw.githubusercontent.com/rskaradag/terraform-works/master/app.py
mkdir templates
cd templates
wget https://raw.githubusercontent.com/rskaradag/terraform-works/master/index.html
cd ..
python3 app.py
