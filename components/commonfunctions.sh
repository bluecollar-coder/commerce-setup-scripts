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
    exit 1
  fi
}

LOG_FILE=/tmp/commerce.log