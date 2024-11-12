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
MONGO_CONTAINER_NAME_DEFAULT="usd-local-mongo"    # -n
MONGO_CONTAINER_PORT_DEFAULT=10801                # -p
MONGO_VOLUME_PATH_DEFAULT="./data/mongodb"        # -v
MONGO_ROOT_USER_DEFAULT="admin"                   # -u
MONGO_ROOT_PASS_DEFAULT="usdlocaladminpass"       # -s

# load default value if not set from environment or config file
fallback() {
  MONGO_CONTAINER_NAME=${MONGO_CONTAINER_NAME:=$MONGO_CONTAINER_NAME_DEFAULT}
  MONGO_CONTAINER_PORT=${MONGO_CONTAINER_PORT:=$MONGO_CONTAINER_PORT_DEFAULT}
  MONGO_VOLUME_PATH=${MONGO_VOLUME_PATH:=$MONGO_VOLUME_PATH_DEFAULT}
  MONGO_ROOT_USER=${MONGO_ROOT_USER:=$MONGO_ROOT_USER_DEFAULT}
  MONGO_ROOT_PASS=${MONGO_ROOT_PASS:=$MONGO_ROOT_PASS_DEFAULT}
}

# load options from command line, it cover fallback()'s functionality as well
buildParams() {
  VALUE_NAME=${name:-${MONGO_CONTAINER_NAME:=$MONGO_CONTAINER_NAME_DEFAULT}}
  VALUE_PORT=${port:-${MONGO_CONTAINER_PORT:=$MONGO_CONTAINER_PORT_DEFAULT}}
  VALUE_VOLUME=${volume:-${MONGO_VOLUME_PATH:=$MONGO_VOLUME_PATH_DEFAULT}}
  VALUE_USER=${user:-${MONGO_ROOT_USER:=$MONGO_ROOT_USER_DEFAULT}}
  VALUE_PASS=${pass:-${MONGO_ROOT_PASS:=$MONGO_ROOT_PASS_DEFAULT}}
}

printParams() {
  echo Parameters ===========================
  echo container name : $VALUE_NAME
  echo container port : $VALUE_PORT
  echo container volume path: $VALUE_VOLUME
  echo MongoDB Root User: $VALUE_USER
  echo MongoDB Root Pass: $VALUE_PASS
  echo ======================================
}

# ============================================================================
# Utility Functions
# ============================================================================

mongoEval() {
  # Concatenate all arguments with format
  local args=$(printf " --eval \"%s\" " "$@")
  execmd="docker exec -i $VALUE_NAME mongosh --port=$VALUE_PORT $args"
  echo "$execmd"
  eval $execmd
}

runMongoContainer() {
  docker run \
    -d --name $VALUE_NAME \
    --hostname $VALUE_NAME \
    -p $VALUE_PORT:$VALUE_PORT \
    -v $VALUE_VOLUME:/data/db \
    --restart=always \
    mongo:8 --replSet=usdrs --bind_ip_all --port $VALUE_PORT
}

# ============================================================================
# Command Functions
# ============================================================================

# Run MongoDB and initiate Replica Set with root user
# Uses VALUE_NAME, VALUE_PORT, VALUE_VOLUME, VALUE_USER, VALUE_PASS
setup() {
  printParams

  # create MongoDB container
  runMongoContainer

  sleep 5

  # initiate Mongo Replica Set
  mongoEval "rs.initiate()"

  # create root user admin
  mongoEval "use admin" "db.createUser( { user: '$VALUE_USER', pwd: '$VALUE_PASS', roles: ['root'] } )"
}

# Stop and Remove MongoDB container
# Uses VALUE_NAME
teardown() {
  docker stop $VALUE_NAME
  docker rm   $VALUE_NAME
}

# Create custom configuration using prompt
custom() {
  read -p "Enter MongoDB Container Name [$MONGO_CONTAINER_NAME]: " MONGO_CONTAINER_NAME
  read -p "Enter MongoDB Container Port [$MONGO_CONTAINER_PORT]: " MONGO_CONTAINER_PORT
  read -p "Enter MongoDB DataVolume Path [$MONGO_VOLUME_PATH]: " MONGO_VOLUME_PATH
  read -p "Enter RootUser Name [$MONGO_ROOT_USER]: " MONGO_ROOT_USER
  read -p "Enter RootUser Password [$MONGO_ROOT_PASS]: " MONGO_ROOT_PASS
  buildParams
}

# Create new database and user
# Uses VALUE_DB_USER, VALUE_DB_PASS from global variables & environment
# Uses VALUE_DB_NAME, VALUE_DB_ROLE set by command line options
create() {
  # if VALUE_DBNAME is empty, ask for database name
  VALUE_DB_NAME=${dbName}
  if [ -z "$VALUE_DB_NAME" ]; then
    read -p "Enter Database Name: " VALUE_DB_NAME
  fi

  # if DB_NAME is default value, ask for user name
  if [ -z "$user" ]; then
    read -p "Enter User Name [${VALUE_DB_NAME}Admin]: " user
  fi
  VALUE_DB_USER=${user:-${VALUE_DB_NAME}Admin}

  # ask password if empty
  if [ -z "$pass" ]; then
    read -p "Enter User Password: " pass
  fi
  # if pass still empty, exit with error
  if [ -z "$pass" ]; then
    echo "Password is required. use --pass or -s option to set password"
    exit 1
  fi
  VALUE_DB_PASS=$pass

  # if role is empty, ask for role
  if [ -z "$role" ]; then
    read -p "Enter User Role (default: "dbOwner"): " role
  fi
  VALUE_DB_ROLE=${role:-"dbOwner"}

  echo ======================================
  echo "new database = $VALUE_DB_NAME"
  echo "user         = $VALUE_DB_USER"
  echo "pass         = $VALUE_DB_PASS"
  echo "role of user = $VALUE_DB_ROLE"
  echo ======================================

  # create database and user
  mongoEval "use $VALUE_DB_NAME" "db.createUser( { user: '$VALUE_DB_USER', pwd: '$VALUE_DB_PASS', roles: [ { role: '$VALUE_DB_ROLE', db: '$VALUE_DB_NAME' } ] } )"
}

# Change hostname of MongoDB node
# Uses VALUE_PORT from global variables & environment
# Uses VALUE_HOSTNAME from command line options
changeHostname(){
  echo "current hostname ======================="
  mongoEval "cfg=rs.conf()" "cfg.members[0].host"
  echo "========================================"

  # if name is not set, ask for name
  if [ -z "$hostname" ]; then
    read -p "Enter new hostname[${VALUE_NAME}]: " hostname
  fi
  VALUE_HOSTNAME=${hostname:-$VALUE_NAME}
  
  # if port is not set, ask for port
  if [ -z "$port" ]; then
    read -p "Enter new port[${VALUE_PORT}]: " port
  fi
  VALUE_NEWPORT=${port:-$VALUE_PORT}

  # if hostname is empty, ask for hostname
  mongoEval "cfg=rs.conf()" "cfg.members[0].host='$VALUE_HOSTNAME:$VALUE_NEWPORT'" "rs.reconfig(cfg)"
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

# load configuration file into global variables
loadConfigFile() {
  unset MONGO_CONTAINER_NAME
  unset MONGO_CONTAINER_PORT
  unset MONGO_VOLUME_PATH
  unset MONGO_ROOT_USER
  unset MONGO_ROOT_PASS

  source $config
  fallback
}

# ============================================================================
# Help Functions
# ============================================================================

help_common() {
  echo "Usage: $0 COMMAND [OPTIONS] [ARGS]"
  echo "Common Commands:
  setup       Create single node replicaSet mongo container.
              aliases: install, up

  teardown    Stop & Remove mongo container
              aliases: uninstall, down, kill

  hostname    Change hostname of MongoDB node
              e.g. $0 hostname        --> will ask for new hostname and port
              e.g. $0 hostname -n localhost -p 27017

  create      Create new database and it's user
              e.g. $0 create          --> ask everything
              e.g. $0 create -d myNewDB -u myNewUser -s myNewPass -r readWrite

  config      Print config file
              e.g. $0 config >> myMongo.conf

  custom      Help to create configuration for this script
              e.g. $0 custom                        --> create config file only : custom_mongo.conf
              e.g. $0 custom myFileName.conf        --> create config file with custom file name
              e.g. $0 custom setup                  --> create config file and setup mongo : custom_mongo.conf
              e.g. $0 custom setup myFileName.conf  --> create config file and setup mongo with custom name

  help        Print help
  "
  echo "Global Options:
  -c          path of configuration file. If config file specified,
              environment variable & command line parameters will be ignored
  -h          each command has its own help. e.g. $0 install -h
  "
  exit 2
}

help_setup(){
  echo "Usage: $0 setup [OPTIONS]"
  echo "Setup Options:
  -n    name and host name of MongoDB container
  -p    port to be exposed
  -v    path of container's dataVolume
  -u    username for root privilege
  -s    password of root user
  "
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variable & command line parameters will be ignored
  "
  exit 2
}

help_teardown(){
  echo "Usage: $0 teardown [OPTIONS]"
  echo "Teardown Options:
  -n    name and host name of MongoDB container
  "
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variable & command line parameters will be ignored
  "
  exit 2
}

help_changeHostname(){
  echo "Usage: $0 hostname [OPTIONS]"
  echo "Change Hostname Options:
  -t    name and hostname of MongoDB node
  -p    port to be exposed
  "
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variable & command line parameters will be ignored
  "
  exit 2
}


help_create(){
  echo "Usage: $0 create [OPTIONS]"
  echo "Create Options:
  -n    name of MongoDB container
  -d    name of database to be created
  -u    username for new database
  -s    password of new user
  -r    role of user (default: dbOwner) e.g. read, readWrite
  "
  echo "Global Options:
  -c    path of configuration file. If config file specified,
        environment variable & command line parameters will be ignored
  "
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
      dbName=$OPTARG
      ;;
    r)
      role=$OPTARG
      ;;
    t)
      hostname=$OPTARG
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
case "$command" in
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
  hostname )
    changeHostname
    ;;
  create)
    if [ -n "$help" ]; then
      help_create
    fi
    create
    ;;
  params)
    printParams
    ;;
  config)
    printConfig
    ;;
  help)
    help_common
    ;;
  *)
    help_common
    ;;
esac
