#!/bin/bash
# Скрипт восстановления базы и настройки репликации

# Аргумент: файл бэкапа
BACKUP_FILE=$1


# ВПИШИ СЮДА IP ТВОЕГО МАСТЕРА
MASTER_HOST="192.168.1.23" 
# ==========================================

DB_USER="root"
DB_PASSWORD="root"
SLAVE_CONTAINER="db-slave"

# Проверка, что файл передан
if [ -z "$BACKUP_FILE" ]; then
  echo "Ошибка: Укажите файл бэкапа."
  echo "Пример: ./scripts/restore.sh dump.sql"
  exit 1
fi

echo "=== 1. Загружаем дамп $BACKUP_FILE в базу ==="
cat $BACKUP_FILE | docker exec -i $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD diplom_db

echo "=== 2. Читаем координаты из файла (парсинг) ==="
# Ищем строки CHANGE MASTER TO... внутри файла
LOG_FILE=$(grep -m 1 "MASTER_LOG_FILE" $BACKUP_FILE | awk -F"'" '{print $2}')
LOG_POS=$(grep -m 1 "MASTER_LOG_POS" $BACKUP_FILE | awk -F"=" '{print $3}' | awk -F";" '{print $1}')

echo "Бинлог: $LOG_FILE"
echo "Позиция: $LOG_POS"

echo "=== 3. Настраиваем репликацию ==="
docker exec $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "STOP SLAVE;"
docker exec $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "RESET SLAVE;"
docker exec $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='user', MASTER_PASSWORD='password', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS;"
docker exec $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "START SLAVE;"

echo "=== ГОТОВО! Статус репликации: ==="
docker exec $SLAVE_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "SHOW SLAVE STATUS \G" | grep "Running:"