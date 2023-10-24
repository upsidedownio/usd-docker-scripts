#!/bin/bash

# Loading Parameters Priority
# 1. commandline options
# 2. config file (overwrite environment variables)
# 3. environment variable
# 4. default

# List of Params
# tag         t
# name        n
# port        p
# cmd         m
# dataVolume  v
# user        u
# pass        s
# rootPass    r
#[config]     c

# parameter defaults
MYSQL_IMAGE_TAG_DEFAULT="8"
MYSQL_CONTAINER_NAME_DEFAULT="usd-local-mongo"
MYSQL_CONTAINER_PORT_DEFAULT=10802
MYSQL_CONTAINER_CMD_DEFAULT="--character-set-server=utf8mb4 --collation-server=utf8mb4_0900_ai_ci --default-time-zone=+00:00"
MYSQL_VOLUME_PATH_DEFAULT="./data/mysql"
MYSQL_ADMIN_USER_DEFAULT="usdadmin"
MYSQL_ADMIN_PASS_DEFAULT="usdlocaladminpass"
MYSQL_ROOT_PASS_DEFAULT="usdlocalrootpass"

default() {
  MYSQL_IMAGE_TAG=$MYSQL_IMAGE_TAG_DEFAULT
  MYSQL_CONTAINER_NAME=$MYSQL_CONTAINER_NAME_DEFAULT
  MYSQL_CONTAINER_PORT=$MYSQL_CONTAINER_PORT_DEFAULT
  MYSQL_CONTAINER_CMD=$MYSQL_CONTAINER_CMD_DEFAULT
  MYSQL_ADMIN_USER=$MYSQL_ADMIN_USER_DEFAULT
  MYSQL_ADMIN_PASS=$MYSQL_ADMIN_PASS_DEFAULT
  MYSQL_VOLUME_PATH=$MYSQL_VOLUME_PATH_DEFAULT
  MYSQL_ROOT_PASS=$MYSQL_ROOT_PASS_DEFAULT
}

fallback() {
  MYSQL_IMAGE_TAG=${MYSQL_IMAGE_TAG:-$MYSQL_IMAGE_TAG_DEFAULT}
  MYSQL_CONTAINER_NAME=${MYSQL_CONTAINER_NAME:-$MYSQL_CONTAINER_NAME_DEFAULT}
  MYSQL_CONTAINER_PORT=${MYSQL_CONTAINER_PORT:-$MYSQL_CONTAINER_PORT_DEFAULT}
  MYSQL_CONTAINER_CMD=${MYSQL_CONTAINER_CMD:-$MYSQL_CONTAINER_CMD_DEFAULT}
  MYSQL_VOLUME_PATH=${MYSQL_VOLUME_PATH:-$MYSQL_VOLUME_PATH_DEFAULT}
  MYSQL_ADMIN_USER=${MYSQL_ADMIN_USER:-$MYSQL_ADMIN_USER_DEFAULT}
  MYSQL_ADMIN_PASS=${MYSQL_ADMIN_PASS:-$MYSQL_ADMIN_PASS_DEFAULT}
  MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-$MYSQL_ROOT_PASS_DEFAULT}
}

buildParams() {
  VALUE_TAG=${tag:=${MYSQL_IMAGE_TAG:=$MYSQL_IMAGE_TAG_DEFAULT}}
  VALUE_NAME=${name:=${MYSQL_CONTAINER_NAME:=$MYSQL_CONTAINER_NAME_DEFAULT}}
  VALUE_PORT=${port:=${MYSQL_CONTAINER_PORT:=$MYSQL_CONTAINER_PORT_DEFAULT}}
  VALUE_CMD=${cmd:=${MYSQL_CONTAINER_CMD:=$MYSQL_CONTAINER_CMD_DEFAULT}}
  VALUE_VOLUME=${volume:=${MYSQL_VOLUME_PATH:=$MYSQL_VOLUME_PATH_DEFAULT}}
  VALUE_USER=${user:=${MYSQL_ADMIN_USER:=$MYSQL_ADMIN_USER_DEFAULT}}
  VALUE_PASS=${pass:=${MYSQL_ADMIN_PASS:=$MYSQL_ADMIN_PASS_DEFAULT}}
  VALUE_ROOT=${root:=${MYSQL_ROOT_PASS:=$MYSQL_ROOT_PASS_DEFAULT}}
}

printParams() {
  echo Parameters ===============
  echo MySQL image tag : $VALUE_TAG
  echo container name : $VALUE_NAME
  echo container port : $VALUE_PORT
  echo container cmd : "$VALUE_CMD"
  echo container volume path: $VALUE_VOLUME
  echo MySQL Admin User: $VALUE_USER
  echo MySQL Admin Pass: $VALUE_PASS
  echo MySQL Root Pass: $VALUE_ROOT
  echo ==========================
}

custom() {
  read -p "Enter MySQL Image Tag [$MYSQL_MYSQL_IMAGE_TAG]: " MYSQL_MYSQL_IMAGE_TAG
  read -p "Enter MySQL Container Name [$MYSQL_CONTAINER_NAME]: " MYSQL_CONTAINER_NAME
  read -p "Enter MySQL Container Port [$MYSQL_CONTAINER_PORT]: " MYSQL_CONTAINER_PORT
  read -p "Enter MySQL Container CMD [$MYSQL_CONTAINER_CMD]: " MYSQL_CONTAINER_CMD
  read -p "Enter MySQL DataVolume Path [$MYSQL_VOLUME_PATH]: " MYSQL_VOLUME_PATH
  read -p "Enter MySQL AdminUser Name [$MYSQL_ADMIN_USER]: " MYSQL_ADMIN_USER
  read -p "Enter MySQL AdminUser Password [$MYSQL_ADMIN_PASS]: " MYSQL_ADMIN_PASS
  read -p "Enter MySQL ROOT Password [$MYSQL_ROOT_PASS]: " MYSQL_ROOT_PASS
  buildParams
}

printConfig(){
  echo "#!/bin/bash"
  echo "export MYSQL_MYSQL_IMAGE_TAG=$VALUE_TAG"
  echo "export MYSQL_CONTAINER_NAME=$VALUE_NAME"
  echo "export MYSQL_CONTAINER_PORT=$VALUE_PORT"
  echo "export MYSQL_CONTAINER_CMD=$VALUE_CMD"
  echo "export MYSQL_VOLUME_PATH=$VALUE_VOLUME"
  echo "export MYSQL_ADMIN_USER=$VALUE_USER"
  echo "export MYSQL_ADMIN_PASS=$VALUE_PASS"
  echo "export MYSQL_ROOT_PASS=$VALUE_ROOT"
  echo ""
}

loadConfigFile() {
  unset MYSQL_MYSQL_IMAGE_TAG
  unset MYSQL_CONTAINER_NAME
  unset MYSQL_CONTAINER_PORT
  unset MYSQL_CONTAINER_CMD
  unset MYSQL_VOLUME_PATH
  unset MYSQL_ADMIN_USER
  unset MYSQL_ADMIN_PASS
  unset MYSQL_ROOT_PASS

  source $config
  fallback

  VALUE_TAG=$MYSQL_MYSQL_IMAGE_TAG
  VALUE_NAME=$MYSQL_CONTAINER_NAME
  VALUE_PORT=$MYSQL_CONTAINER_PORT
  VALUE_CMD=$MYSQL_CONTAINER_CMD
  VALUE_VOLUME=$MYSQL_VOLUME_PATH
  VALUE_USER=$MYSQL_ADMIN_USER
  VALUE_PASS=$MYSQL_ADMIN_PASS
  VALUE_ROOT=$MYSQL_ROOT_PASS
}

# actions
setup() {
  printParams
}

runMySqlContainer() {
  docker run  --name $VALUE_NAME \
              --hostname $VALUE_NAME \
              -e MYSQL_ROOT_PASSWORD=$VALUE_ROOT \
              -e MYSQL_USER=$VALUE_USER \
              -e MYSQL_PASSWORD=$VALUE_PASS \
              -e MYSQL_INITDB_SKIP_TZINFO=true \
              -d mysql:$VALUE_TAG "$VALUE_CMD"

#MYSQL_DATABASE
}

createDataBase() {
#  TODO
  docker run exec
}

teardown() {
  docker stop $VALUE_NAME
  docker rm   $VALUE_NAME
}


# helps

help_common() {
#  TODO
  echo "Usage: usdMySQL COMMAND [OPTIONS]\n"
  echo "Common Commands:
  setup       Create single mongo container.
              then setup replicaSet and root user
              aliases: s, install, up

  teardown    Stop & Remove mongo container
              aliases: t, unintall, down

  config      Print config file
              e.g. usdMySQL config >> myMongo.conf

  help        Print help
  "
  echo "Global Options:
  -c,   --config string       path of configuration file. If config file specified,
                              environment variable & command line parameters will be ignored"
  exit 2
}

help_setup(){
#  TODO
  echo -e "Usage: usdMySQL setup [OPTIONS]\n"
  echo "Setup Options:
  -n, --name        name and host name of MongoDB container
  -p, --port        port to be exposed
  -v, --dataVolume  path of container's dataVolume
  -u, --user        username for root privilege
  -s, --pass        password of root user
  "
  echo -e "Global Options:
    -c,   --config string       path of configuration file. If config file specified,
                                environment variable & command line parameters will be ignored"
  exit 2
}

help_teardown(){
#  TODO
  echo -e "Usage: usdMySQL teardown [OPTIONS]\n"
  echo -e "Teardown Options:
  -n, --name        name and host name of MongoDB container\n"
  echo -e "Global Options:
    -c,   --config string       path of configuration file. If config file specified,
                                environment variable & command line parameters will be ignored"
  exit 2
}

SHORT=c:,n:,p:,v:,u:,s:,h
LONG=config:,name:,port:,dataVolume:,datavolume:,user:,pass:,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")
eval set -- "$OPTS"

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help_common
fi

while :
do
  case "$1" in
    -c | --config )
      config="$2"
      shift 2
      ;;
    -n | --name )
      name="$2"
      shift 2
      ;;
    -p | --port )
      port="$2"
      shift 2
      ;;
    -v | --dataVolume | --datavolume )
      volume="$2"
      shift 2
      ;;
    -u | --user )
      user="$2"
      shift 2
      ;;
    -s | --pass )
      pass="$2"
      shift 2
      ;;
    -h | --help)
      help="true"
      shift 1
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help_common
      ;;
  esac
done

buildParams

# If the configuration file is specified,
#  All environment variables and command line parameters will be ignored.
if [ -n "$config" ]; then
  if [ -f "$config" ]; then
    echo "config file specified, environment variables & commandline parameters will be ignores"
    loadConfigFile

  else
    echo "'$config' is not a file."
    exit 1
  fi
fi

# =============================
# Run Functions
case "$1" in
  setup | install)
    if [ -n "$help" ]; then
      help_setup
    fi
    setup
    ;;
  teardown | down | kill | uninstall)
    if [ -n "$help" ]; then
      help_teardown
    fi
    teardown
    ;;
  custom)
    custom
    case "$2" in
      setup)
        setup
        ;;
      teardown)
        teardown
        ;;
      *)
        ;;
    esac
    echo "================================="
    echo "use below config script for later"
    echo "================================="
    printConfig
    echo "================================="
    ;;
  params)
    printParams
    ;;
  config)
    buildParams
    printConfig
    ;;
  help)
    help_common
    ;;
  *)
    help_common
    ;;
esac
