#!/usr/bin/env bash

USER_ID=$(id -u)
if [ "$USER_ID" -ne 0 ]; then
  echo "You are supposed to run script as a root user"
else
 yum install nginx -y
 systemctl enable nginx
 systemctl start nginx
 curl -s -L -o /tmp/frontend.zip "https://github.com/roboshop-devops-project/frontend/archive/main.zip"
 cd /usr/share/nginx/html
 rm -rf *
 unzip /tmp/frontend.zip
 mv frontend-main/* .
 mv static/* .
 rm -rf frontend-master README.md
 mv localhost.conf /etc/nginx/default.d/roboshop.conf
 systemctl restart nginx
 fi