#!/bin/bash
set -e

CONTAINER_NAME="my-python-app"
ROOTFS_DIR="./rootfs"

echo "[*] Создаём rootfs с Python..."

# 1️⃣ Скачиваем Python образ
docker pull python:3.12-alpine

# 2️⃣ Создаём контейнер и экспортируем его rootfs
docker create --name tmp-python python:3.12-alpine
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR
docker export tmp-python | tar -C $ROOTFS_DIR -xf -
docker rm tmp-python

echo "[*] Копируем приложение app.py..."
mkdir -p $ROOTFS_DIR/app
cat > $ROOTFS_DIR/app/app.py <<'EOF'
print("Hello from runC!")
EOF

echo "[*] Генерируем базовый config.json..."
rm -f config.json
runc spec

echo "[*] Настраиваем config.json..."
# Меняем рабочий каталог, args и rootfs
jq '.process.cwd="/app" | .process.args=["python3","/app/app.py"] | .process.terminal=true | .process.user.uid=0 | .process.user.gid=0 | .root.path="./rootfs" | .root.readonly=false' config.json > config.tmp.json
mv config.tmp.json config.json

echo "[*] Запускаем контейнер..."
sudo runc run $CONTAINER_NAME

echo "[*] Очистка..."
sudo runc delete $CONTAINER_NAME || true

echo "[*] Готово!"

