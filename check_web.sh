#!/bin/bash

WEBROOT="/var/www/html"
INDEX_FILE="${WEBROOT}/index.html"

# Проверка порта 80
ss -lnt | grep -q ':80 '

if [ $? -ne 0 ]; then
    exit 1
fi

# Проверка существования index.html
if [ ! -f "$INDEX_FILE" ]; then
    exit 1
fi

exit 0