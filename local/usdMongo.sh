#!/bin/bash

# Loading Parameters Priority
# 1. commandline options
# 2. config file (overwrite environment variables)
# 3. environment variable
# 4. default

# List of Params
# name  n
# port  p
# dataVolume  v
# user  u
# pass  s
# config c

# parameter defaults
MONGO_CONTAINER_NAME_DEFAULT="usd-local-mongo"
MONGO_CONTAINER_PORT_DEFAULT=10801
MONGO_VOLUME_PATH_DEFAULT="./data/mongodb"
MONGO_ROOT_USER_DEFAULT="admin"
MONGO_ROOT_PASS_DEFAULT="usdlocaladminpass"

default() {
  MONGO_CONTAINER_NAME=$MONGO_CONTAINER_NAME_DEFAULT
  MONGO_CONTAINER_PORT=$MONGO_CONTAINER_PORT_DEFAULT
  MONGO_ROOT_USER=$MONGO_ROOT_USER_DEFAULT
  MONGO_ROOT_PASS=$MONGO_ROOT_PASS_DEFAULT
  MONGO_VOLUME_PATH=$MONGO_VOLUME_PATH_DEFAULT
}

fallback() {
  MONGO_CONTAINER_NAME=${MONGO_CONTAINER_NAME:-$MONGO_CONTAINER_NAME_DEFAULT}
  MONGO_CONTAINER_PORT=${MONGO_CONTAINER_PORT:-$MONGO_CONTAINER_PORT_DEFAULT}
  MONGO_VOLUME_PATH=${MONGO_VOLUME_PATH:-$MONGO_VOLUME_PATH_DEFAULT}
  MONGO_ROOT_USER=${MONGO_ROOT_USER:-$MONGO_ROOT_USER_DEFAULT}
  MONGO_ROOT_PASS=${MONGO_ROOT_PASS:-$MONGO_ROOT_PASS_DEFAULT}
}

buildParams() {
  VALUE_NAME=${name:=${MONGO_CONTAINER_NAME:=$MONGO_CONTAINER_NAME_DEFAULT}}
  VALUE_PORT=${port:=${MONGO_CONTAINER_PORT:=$MONGO_CONTAINER_PORT_DEFAULT}}
  VALUE_VOLUME=${volume:=${MONGO_VOLUME_PATH:=$MONGO_VOLUME_PATH_DEFAULT}}
  VALUE_USER=${user:=${MONGO_ROOT_USER:=$MONGO_ROOT_USER_DEFAULT}}
  VALUE_PASS=${pass:=${MONGO_ROOT_PASS:=$MONGO_ROOT_PASS_DEFAULT}}
}

printParams() {
  echo Parameters ===============
  echo container name : $VALUE_NAME
  echo container port : $VALUE_PORT
  echo container volume path: $VALUE_VOLUME
  echo MongoDB Root User: $VALUE_USER
  echo MongoDB Root Pass: $VALUE_PASS
  echo ==========================
}

setup() {
  printParams

  # create MongoDB container
  runMongoContainer
  # initiate replica set
  initiateMongoReplicaSet
  # create root user
  createMongoRootUser
}

runMongoContainer() {
  docker run -d --name $VALUE_NAME \
    --hostname $VALUE_NAME \
    -p $VALUE_PORT:27017 \
    -v $VALUE_VOLUME:/data/db \
    --restart=always \
    mongo --replSet=usdrs --bind_ip_all
}

initiateMongoReplicaSet() {
  docker exec -i $VALUE_NAME sh -c "mongosh --eval \"use admin\" --eval \"rs.initiate()\""
}

createMongoRootUser(){
  docker exec -i $VALUE_NAME sh -c "mongosh --eval \"use admin\" --eval \"db.createUser( { user: '$VALUE_USER', pwd: '$VALUE_PASS', roles: ['root'] } )\""
}

teardown() {
  docker stop $VALUE_NAME
  docker rm   $VALUE_NAME
}

custom() {
  read -p "Enter MongoDB Container Name [$MONGO_CONTAINER_NAME]: " MONGO_CONTAINER_NAME
  read -p "Enter MongoDB Container Port [$MONGO_CONTAINER_PORT]: " MONGO_CONTAINER_PORT
  read -p "Enter MongoDB DataVolume Path [$MONGO_VOLUME_PATH]: " MONGO_VOLUME_PATH
  read -p "Enter RootUser Name [$MONGO_ROOT_USER]: " MONGO_ROOT_USER
  read -p "Enter RootUser Password [$MONGO_ROOT_PASS]: " MONGO_ROOT_PASS
  buildParams
}

printConfig(){
  echo "#!/bin/bash"
  echo "export MONGO_CONTAINER_NAME=$VALUE_NAME"
  echo "export MONGO_CONTAINER_PORT=$VALUE_PORT"
  echo "export MONGO_ROOT_USER=$VALUE_VOLUME"
  echo "export MONGO_ROOT_PASS=$VALUE_USER"
  echo "export MONGO_VOLUME_PATH=$VALUE_PASS"
  echo ""
}

loadConfigFile() {
  unset MONGO_CONTAINER_NAME
  unset MONGO_CONTAINER_PORT
  unset MONGO_VOLUME_PATH
  unset MONGO_ROOT_USER
  unset MONGO_ROOT_PASS

  source $config
  fallback
  VALUE_NAME=$MONGO_CONTAINER_NAME
  VALUE_PORT=$MONGO_CONTAINER_PORT
  VALUE_VOLUME=$MONGO_VOLUME_PATH
  VALUE_USER=$MONGO_ROOT_USER
  VALUE_PASS=$MONGO_ROOT_PASS
}


help_common() {
  echo "Usage: usdMongo COMMAND [OPTIONS]\n"
  echo "Common Commands:
  setup       Create single mongo container.
              then setup replicaSet and root user
              aliases: s, install, up

  teardown    Stop & Remove mongo container
              aliases: t, unintall, down

  config      Print config file
              e.g. usdMongo config >> myMongo.conf

  help        Print help
  "
  echo "Global Options:
  -c,   --config string       path of configuration file. If config file specified,
                              environment variable & command line parameters will be ignored"
  exit 2
}

help_setup(){
  echo -e "Usage: usdMongo setup [OPTIONS]\n"
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
  echo -e "Usage: usdMongo teardown [OPTIONS]\n"
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
