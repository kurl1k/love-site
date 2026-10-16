#!/bin/bash
# Love Site — быстрая установка
# Использование: sudo bash install.sh [порт]

PORT=${1:-64321}
INSTALL_DIR="/var/www/love"

echo "=== Установка Love Site на порт $PORT ==="

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Запусти с sudo: sudo bash install.sh"
  exit 1
fi

# Устанавливаем nginx, если нет
if ! command -v nginx &> /dev/null; then
  echo "[*] Устанавливаю nginx..."
  apt update && apt install -y nginx
fi

# Копируем файлы
echo "[*] Копирую файлы в $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp index.html "$INSTALL_DIR/"
cp love_you.mp3 "$INSTALL_DIR/"
chmod 644 "$INSTALL_DIR"/*

# Проверяем mime.types
if [ ! -f /etc/nginx/mime.types ]; then
  cat > /etc/nginx/mime.types << 'MIME'
types {
    text/html html htm shtml;
    text/css css;
    text/plain txt;
    application/json json;
    application/javascript js;
    audio/mpeg mp3;
}
MIME
fi

# Конфиг nginx
echo "[*] Настраиваю nginx на порт $PORT..."
cat > /etc/nginx/sites-available/love << NGINX
server {
    listen $PORT;
    server_name _;
    root $INSTALL_DIR;
    index index.html;

    location ~* \.mp3$ {
        types { audio/mpeg mp3; }
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/love /etc/nginx/sites-enabled/love

# Проверка конфига
if ! nginx -t 2>/dev/null; then
  echo "[!] Ошибка в конфиге nginx. Проверь /etc/nginx/nginx.conf"
  exit 1
fi

# Открываем порт
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
  ufw allow $PORT/tcp
fi

systemctl restart nginx

IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo ""
echo "=== Готово! ==="
echo "Открой: http://$IP:$PORT"
echo ""
