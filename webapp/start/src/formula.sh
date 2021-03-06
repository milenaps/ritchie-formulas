#!/bin/sh

runFormula() {
  if [ "$START_DATABASE" == true ]; then
    startDatabase
  fi

  export DEPLOYMENT_FOLDER=$WAR_PATH
  startAppServer

  unset DEPLOYMENT_FOLDER; unset DB_USER; unset DB_PASSWORD; unset DB_SCHEMA;
}

startDatabase() {
  echoColor "blue" "Starting the $SELECTED_DB database"

  export DB_USER=$SELECTED_DB_USER
  export DB_PASSWORD=$SELECTED_DB_PASSWORD
  export DB_SCHEMA=$SELECTED_DB_SCHEMA

  if [ "$SELECTED_DB" == "PostgreSQL" ]; then
    startService "database" "postgres"

    while [[ "$exp" == "" ]]; do
      exp=$(docker ps --filter="name=postgres" -q)
      sleep 2
    done
  fi

  runDBScripts
}

runDBScripts() {
  #---
  #TODO Logic to determine order of scripts splitting number from name
  #---
  if [ "$RUN_DB_SCRIPTS" == true ]; then

    echoColor "green" "Running database scripts"

    for script in "$DB_SCRIPTS_PATH"/*
    do
      if [ "$SELECTED_DB" == "PostgreSQL" ]; then
        cat $script | docker exec -i postgres psql -U $SELECTED_DB_USER -d $SELECTED_DB_SCHEMA
      fi
    done

  fi
}

startAppServer() {
  echoColor "yellow" "Starting the $APPLICATION_SERVER application server"

  case $APPLICATION_SERVER in
    Tomcat)
      startService "app_server" "tomcat"
      ;;
    Payara)
      startService "app_server" "payara"
      ;;
    esac
}

startService() {
  docker-compose -f $1/docker-compose-$2.yml down
  docker-compose -f $1/docker-compose-$2.yml up -d
}

echoColor() {
  case $1 in
    red)
      echo "$(printf '\033[31m')$2$(printf '\033[0m')"
      ;;
    green)
      echo "$(printf '\033[32m')$2$(printf '\033[0m')"
      ;;
    yellow)
      echo "$(printf '\033[33m')$2$(printf '\033[0m')"
      ;;
    blue)
      echo "$(printf '\033[34m')$2$(printf '\033[0m')"
      ;;
    cyan)
      echo "$(printf '\033[36m')$2$(printf '\033[0m')"
      ;;
    esac
}
