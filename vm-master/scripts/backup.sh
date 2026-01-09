#!/bin/bash

# Настройки
CONTAINER_NAME="db-master"
DB_USER="root"
DB_PASS="root"
BACKUP_DIR="./backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="$BACKUP_DIR/full_backup_$DATE.sql"

# Создаем папку для бэкапов, если нет
mkdir -p $BACKUP_DIR

echo "Start backup from $CONTAINER_NAME..."

#
# --all-databases : бэкапим всё
# --master-data=1 : добавляет команду CHANGE MASTER TO (с координатами!)
# --single-transaction : чтобы не блокировать базу во время процесса

sudo docker exec $CONTAINER_NAME mysqldump -u$DB_USER -p$DB_PASS \
  --all-databases \
  --master-data=1 \
  --single-transaction > $FILENAME

echo "Backup saved to: $FILENAME"