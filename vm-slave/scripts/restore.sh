#!/bin/bash

# Параметры подключения к Мастеру (они постоянные)
MASTER_HOST="192.168.1.23"
REPL_USER="repl_user"
REPL_PASSWORD="slave_pass"

# Файл бэкапа (передаем первым аргументом при запуске скрипта)
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "Ошибка: Укажите путь к файлу бэкапа!"
    echo "Пример: ./restore.sh full_backup.sql"
    exit 1
fi

echo "=== Начинаем восстановление Слейва из файла $BACKUP_FILE ==="

# 1. Останавливаем Слейв (на всякий случай)
echo "Stopping Slave..."
sudo docker exec db-slave mysql -u root -proot -e "STOP SLAVE;"

# 2. Прописываем КУДА стучаться (Хост, Юзер, Пароль)
# Координаты (File/Pos) пока не трогаем, они прилетят из файла бэкапа!
echo "Configuring Master Host/User..."
sudo docker exec db-slave mysql -u root -proot -e "CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='$REPL_USER>

# 3. Заливаем бэкап (Данные + Координаты)
echo "Importing Dump (Data + Coordinates)..."
# -i (интерактивно) тут не нужно, используем перенаправление ввода <
sudo docker exec -i db-slave mysql -u root -proot < "$BACKUP_FILE"

# 4. Запускаем Слейв
echo "Starting Slave..."
sudo docker exec db-slave mysql -u root -proot -e "START SLAVE;"

# 5. Проверяем статус
echo "=== STATUS ==="
sudo docker exec db-slave mysql -u root -proot -e "SHOW SLAVE STATUS \G" | grep "Running:"