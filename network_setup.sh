#!/bin/bash

# Предупреждение о потенциальных рисках
echo "Внимание! Выполнение этого скрипта может привести к потере сетевого подключения."
echo "Убедитесь, что вы осознаете свои действия и имеете резервную копию конфигурационных файлов."
read -p "Продолжить? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Продолжение..."
else
  echo "Отмена."
  exit 1
fi

# Проверка прав доступа
if [[ $EUID -ne 0 ]]; then
  echo "Недостаточно прав. Запустите скрипт с правами суперпользователя (sudo)."
  exit 1
fi

# Переменные для хранения новых настроек сети
NEW_IP="$1"
NEW_NETMASK="$2"
NEW_GATEWAY="$3"

# Резервное копирование файла /etc/network/interfaces
cp /etc/network/interfaces /etc/network/interfaces.bak

# Замена IP-адреса в файле /etc/network/interfaces
if [[ ! -z "$NEW_IP" ]]; then
  sed -i "s/address.*$/address $NEW_IP/g" /etc/network/interfaces
fi

# Получение текущей сетевой конфигурации
NETWORK_INFO=$(ip -4 a show | grep -Eo 'inet (.*?)/.*')

# Форматирование вывода
echo "Текущая сетевая конфигурация:"
echo "IP-адрес: $NETWORK_INFO"

# Вывод сообщения об успешном завершении
echo "Конфигурация сети была успешно изменена."

# Логирование действий
echo "Дата: $(date)" >> /var/log/network_setup.log
echo "Скрипт: network_setup.sh" >> /var/log/network_setup.log
echo "Новый IP-адрес: $NEW_IP" >> /var/log/network_setup.log
echo "Новая маска подсети: $NEW_NETMASK" >> /var/log/network_setup.log
echo "Новый шлюз: $NEW_GATEWAY" >> /var/log/network_setup.log

# Перезагрузка сетевого интерфейса
systemctl restart networking

exit 0
