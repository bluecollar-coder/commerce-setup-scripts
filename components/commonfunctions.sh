#!/usr/bin/env bash

checkUserPermissions()
{
  USER_ID=$(id -u)
  if [ "$USER_ID" -ne 0 ]; then
    echo "You are supposed to run script as a root user"
    exit 1
  else
    echo "OK"
  fi
}

statusCheck()
{
  if [ $1 -eq 0 ];then
    echo -e "\e[32m SUCCESS \e[0m"
  else
    echo -e "\e[31m FAILURE \e[0m"
    echo "Check error log in ${LOG_FILE}"
    exit 1
  fi
}

LOG_FILE=/tmp/commerce.log
rm -rf ${LOF_FILE}

ECHO(){
  echo -e "======================$1===============\n" >>${LOG_FILE}
  echo "$1"
}

APPLICATION_SETUP() {
  id roboshop &>>${LOG_FILE}
  if [ $? -ne 0 ]; then
    ECHO "Add Application User"
    useradd roboshop &>>${LOG_FILE}
    statusCheck $?
  fi

  ECHO "Download Application content"
  curl -s -L -o /tmp/${COMPONENT}.zip "https://github.com/roboshop-devops-project/${COMPONENT}/archive/main.zip" &>>${LOG_FILE}
  statusCheck $?

  ECHO "Extract Application archive"
  cd /home/roboshop && rm -rf ${COMPONENT} &>>${LOG_FILE} && unzip /tmp/${COMPONENT}.zip &>>${LOG_FILE}  && mv ${COMPONENT}-main ${COMPONENT}
  statusCheck $?
}

SYSTEMD_SETUP() {
  chown roboshop:roboshop /home/roboshop/${COMPONENT} -R

  ECHO "Update SystemD configuration Files"
  sed -i -e 's/MONGO_DNSNAME/mongodb.roboshop.internal/' -e 's/REDIS_ENDPOINT/redis.roboshop.internal/' -e 's/MONGO_ENDPOINT/mongodb.roboshop.internal/' -e 's/CATALOGUE_ENDPOINT/catalogue.roboshop.internal/' -e 's/CARTENDPOINT/cart.roboshop.internal/' -e 's/DBHOST/mysql.roboshop.internal/' -e 's/CARTHOST/cart.roboshop.internal/' -e 's/USERHOST/user.roboshop.internal/' -e 's/AMQPHOST/rabbitmq.roboshop.internal/' /home/roboshop/${COMPONENT}/systemd.service
  statusCheck $?

  ECHO "Setup SystemD Service"
  mv /home/roboshop/${COMPONENT}/systemd.service  /etc/systemd/system/${COMPONENT}.service
  systemctl daemon-reload &>>${LOG_FILE} && systemctl enable ${COMPONENT} &>>${LOG_FILE} && systemctl restart ${COMPONENT} &>>${LOG_FILE}
  statusCheck $?
}


NODEJS() {
  ECHO "Configure NodeJS yum repos"
  curl -sL https://rpm.nodesource.com/setup_lts.x | bash  &>>${LOG_FILE}
  statusCheck $?

  ECHO "Install NodeJS"
  yum install nodejs  gcc-c++ -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Install NodeJS modules"
  cd /home/roboshop/${COMPONENT} && npm install &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP
}

JAVA() {
  ECHO "Installing Java & Maven"
  yum install maven -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Compile Build-Automation tool(for Java) named Mavan"
  cd /home/roboshop/${COMPONENT} && mvn clean package &>>${LOG_FILE} && mv target/${COMPONENT}-1.0.jar ${COMPONENT}.jar &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP
}

PYTHON() {
  ECHO "Installing Python"
  yum install python36 gcc python3-devel -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Install Python dependencies"
  cd /home/roboshop/${COMPONENT} && pip3 install -r requirements.txt &>>${LOG_FILE}
  statusCheck $?

  USER_ID=$(id -u roboshop)
  GROUP_ID=$(id -g roboshop)

  ECHO "Update Commerce configurations"
  sed -i -e "/^uid/ c uid = ${USER_ID}" -e "/^gid/ c gid = ${GROUP_ID}" /home/roboshop/${COMPONENT}/${COMPONENT}.ini &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP
}