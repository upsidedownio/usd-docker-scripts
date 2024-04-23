#!/bin/bash

# ============================================================================
# Global Variables
# ============================================================================

# Loading Parameters Priority
# 1. commandline options
# 2. config file (overwrite environment variables)
# 3. environment variable
# 4. default

# parameter defaults
MYSQL_IMAGE_TAG_DEFAULT="8"
MYSQL_CONTAINER_NAME_DEFAULT="usd-local-mysql"
MYSQL_CONTAINER_PORT_DEFAULT=10802
MYSQL_CONTAINER_CMD_DEFAULT="--character-set-server=utf8mb4 --collation-server=utf8mb4_0900_ai_ci --default-time-zone=+00:00"
MYSQL_VOLUME_PATH_DEFAULT="./data/mysql"
MYSQL_ADMIN_USER_DEFAULT="usdadmin"
MYSQL_ADMIN_PASS_DEFAULT="usdlocaladminpass"
MYSQL_ROOT_PASS_DEFAULT="usdlocalrootpass"

# load default value if not set from environment or config file
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

# load options from command line, it cover fallback()'s functionality as well
buildParams() {
  VALUE_TAG=${tag:-${MYSQL_IMAGE_TAG:=$MYSQL_IMAGE_TAG_DEFAULT}}
  VALUE_NAME=${name:-${MYSQL_CONTAINER_NAME:=$MYSQL_CONTAINER_NAME_DEFAULT}}
  VALUE_PORT=${port:-${MYSQL_CONTAINER_PORT:=$MYSQL_CONTAINER_PORT_DEFAULT}}
  VALUE_CMD=${cmd:-${MYSQL_CONTAINER_CMD:=$MYSQL_CONTAINER_CMD_DEFAULT}}
  VALUE_VOLUME=${volume:-${MYSQL_VOLUME_PATH:=$MYSQL_VOLUME_PATH_DEFAULT}}
  VALUE_USER=${user:-${MYSQL_ADMIN_USER:=$MYSQL_ADMIN_USER_DEFAULT}}
  VALUE_PASS=${pass:-${MYSQL_ADMIN_PASS:=$MYSQL_ADMIN_PASS_DEFAULT}}
  VALUE_ROOT=${root:-${MYSQL_ROOT_PASS:=$MYSQL_ROOT_PASS_DEFAULT}}
}

printParams() {
  echo Parameters ===========================
  echo MySQL image tag : $VALUE_TAG
  echo container name : $VALUE_NAME
  echo container port : $VALUE_PORT
  echo container cmd : "$VALUE_CMD"
  echo container volume path: $VALUE_VOLUME
  echo MySQL Admin User: $VALUE_USER
  echo MySQL Admin Pass: $VALUE_PASS
  echo MySQL Root Pass: $VALUE_ROOT
  echo ======================================
}

# ============================================================================
# Utility Functions
# ============================================================================

runMySqlContainer() {
  docker run  --name $VALUE_NAME \
              --hostname $VALUE_NAME \
              -v $VALUE_VOLUME:/var/lib/mysql \
              -p $VALUE_PORT:3306 \
              -e MYSQL_ROOT_PASSWORD=$VALUE_ROOT \
              -e MYSQL_USER=$VALUE_USER \
              -e MYSQL_PASSWORD=$VALUE_PASS \
              -e MYSQL_INITDB_SKIP_TZINFO=true \
              -d mysql:$VALUE_TAG "$VALUE_CMD"
}

# ============================================================================
# Command Functions
# ============================================================================

setup() {
  runMySqlContainer
}

teardown() {
  docker stop $VALUE_NAME
  docker rm   $VALUE_NAME
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

# TODO create db

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
}

# ============================================================================
# Help Functions
# ============================================================================

help_common() {
  echo "Usage: $0 COMMAND [OPTIONS] [ARGS]"
  echo "Common Commands:
  setup       Create mysql container
              aliases: install, up

  teardown    Stop & Remove mysql container
              aliases: uninstall, down, kill

  config      Print config file
              e.g. $0 config
              e.g. $0 config >> myMysql.conf

  custom      Help to create configuration for this script
              e.g. $0 custom                        --> create config file only : custom_mysql.conf
              e.g. $0 custom myFileName.conf        --> create config file with custom file name
              e.g. $0 custom setup                  --> create config file and setup mysql : custom_mysql.conf
              e.g. $0 custom setup myFileName.conf  --> create config file and setup mysql with custom name

  help        Print help
  "
  echo "Global Options:
  -c          path of configuration file. If config file specified,
              environment variables will be ignored
  -h          each command has its own help. e.g. $0 install -h
  "
  exit 2
}

help_setup(){
  echo "Usage: $0 setup [OPTIONS]"
  echo "Setup Options:
  -n    name and host name of MySQL container
  -p    port to be exposed
  -v    path of container's dataVolume
  -u    username for root privilege
  -s    password of new user
  -r    password of root
  -d    command to be executed when container starts (with mysql)
  -t    tag of MySQL image (version)
  "
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variables will be ignored"
  exit 2
}

help_teardown(){
  echo "Usage: $0 teardown [OPTIONS]"
  echo "Teardown Options:
  -n    name and host name of MySQL container"
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variables will be ignored"
  exit 2
}

# ============================================================================
# Executing Script
# ============================================================================

# 1. Parse Command
command=$1
shift
if [ -z "$command" ]; then
  help_common
fi

# 2. Parse Options
optstring=":c:n:p:v:u:s:d:r:t:h"
while getopts ${optstring} opt; do
  OPTARG=${OPTARG#=}
  case ${opt} in
    c)
      config=$OPTARG
      ;;
    n)
      name=$OPTARG
      ;;
    p)
      port=$OPTARG
      ;;
    v)
      volume=$OPTARG
      ;;
    u)
      user=$OPTARG
      ;;
    s)
      pass=$OPTARG
      ;;
    d)
      cmd=$OPTARG
      ;;
    r)
      root=$OPTARG
      ;;
    t)
      tag=$OPTARG
      ;;
    h)
      help="true"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# 3. Load Configuration File
if [ -n "$config" ]; then
  if [ -f "$config" ]; then
    echo "config file specified, all environment variables are ignored."
    loadConfigFile

  else
    echo "'$config' is not a file."
    exit 1
  fi
fi

# 4. Build Parameters
buildParams

# 5. Execute Command
case "$1" in
  setup | install | up)
    if [ -n "$help" ]; then
      help_setup
    fi
    setup
    ;;
  teardown | uninstall | down | kill )
    if [ -n "$help" ]; then
      help_teardown
    fi
    teardown
    ;;
  custom)
    custom
    case "$1" in
      setup | install | up)
        setup
        # if $2 is not empty assign that into FILENAME
        if [ -n "$2" ]; then
          FILENAME="$2"
        fi
        ;;
      teardown | uninstall | down | kill)
        teardown
        if [ -n "$2" ]; then
          FILENAME="$2"
        fi
        ;;
      *)
        FILENAME="custom_mongo.conf"
        if [ -n "$1" ]; then
          FILENAME="$1"
        fi
        ;;
    esac
    echo "================================="
    echo "use below config script for later"
    echo "filename: $FILENAME"
    echo "================================="
    printConfig | tee $FILENAME
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
