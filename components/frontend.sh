#!/usr/bin/env bash

source components/commonfunctions.sh
checkUserPermissions

ECHO "Installing Nginx"
yum install nginx -y &>>${LOG_FILE}
statusCheck $?

ECHO "Downloading Frontend Code"
curl -s -L -o /tmp/frontend.zip "https://github.com/roboshop-devops-project/frontend/archive/main.zip" &>>${LOG_FILE}
statusCheck $?

cd /usr/share/nginx/html

ECHO "Removing Old Files"
rm -rf * &>>${LOG_FILE}
statusCheck $?

ECHO "Extracting Zip Content"
unzip /tmp/frontend.zip &>>${LOG_FILE}
statusCheck $?

ECHO "Copying extracted Content"
mv frontend-main/* . &>>${LOG_FILE} && mv static/* . &>>${LOG_FILE} && rm -rf frontend-main README.md &>>${LOG_FILE}
statusCheck $?

ECHO "Copy RoboShop Nginx Config"
mv localhost.conf /etc/nginx/default.d/roboshop.conf &>>${LOG_FILE}
statusCheck $?

ECHO "Start Nginx Service"
systemctl enable nginx &>>${LOG_FILE} && systemctl restart nginx &>>${LOG_FILE}
statusCheck $?