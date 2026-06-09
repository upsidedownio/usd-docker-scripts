# Prerequisites
* docker
* user who execute utilities below must be in docker group

# Quick Start

## MongoDB

### Setup
```bash
./local/usdMongo.sh setup
```

### Create Database & User for each service
```bash
./local/usdMongo.sh create
```

### Configuration

#### Option1: update /etc/hosts/
```
127.0.0.1 usd-local-mongo
```

#### Option2: use DirectConnection option on url
```
mongodb://localhost:10801/dbName?directConnection=true
```
