#!/bin/bash

# Функция для вывода сообщения об ошибке и выхода из скрипта
error_exit() {
  echo "Ошибка: $1" >&2
  exit 1
}

# Функция для логирования действий скрипта
log() {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$timestamp: $1" >> /var/log/network_setup.log
}

# Проверка наличия root-прав
if [[ $EUID -ne 0 ]]; then
  error_exit "Для выполнения этого скрипта требуются права root. Используйте sudo."
fi

# Получение аргументов командной строки
NEW_IP=$1
NEW_NETMASK=$2
NEW_GATEWAY=$3
INTERFACE=$4

# Проверка наличия всех необходимых аргументов
if [[ -z "$NEW_IP" || -z "$NEW_NETMASK" || -z "$NEW_GATEWAY" || -z "$INTERFACE" ]]; then
  echo "Необходимо указать IP-адрес, маску подсети, шлюз и интерфейс."
  echo "Использование: $0 <new_ip> <new_netmask> <new_gateway> <interface>"
  exit 1
fi

# Создание резервной копии файла конфигурации
cp /etc/network/interfaces /etc/network/interfaces.bak || error_exit "Не удалось создать резервную копию /etc/network/interfaces"
log "Создана резервная копия /etc/network/interfaces"

# Изменение конфигурации сети
sed -i "s/address\s\+.*$/address $NEW_IP/g" /etc/network/interfaces || error_exit "Не удалось изменить IP-адрес."
sed -i "s/netmask\s\+.*$/netmask $NEW_NETMASK/g" /etc/network/interfaces || error_exit "Не удалось изменить маску подсети."
sed -i "s/gateway\s\+.*$/gateway $NEW_GATEWAY/g" /etc/network/interfaces || error_exit "Не удалось изменить шлюз."
log "Конфигурация сети успешно изменена в /etc/network/interfaces"

# Перезапуск сетевых служб
systemctl restart networking || error_exit "Не удалось перезапустить сетевые службы."
log "Сетевые службы перезапущены."

# Получение информации о текущей сетевой конфигурации
NETWORK_INFO=$(ip -4 addr show dev $INTERFACE | grep inet)

# Форматирование вывода
echo "Текущая сетевая конфигурация для $INTERFACE:"
echo "$NETWORK_INFO"

# Вывод сообщения об успешном завершении задачи
echo "Конфигурация сети успешно изменена."

# Логирование действий
log "Скрипт network_setup.sh был успешно выполнен."

# Предупреждение пользователя
echo "Предупреждение: Изменение сетевой конфигурации может повлиять на подключение к сети."
echo "Проверьте, что вы осознаете свои действия."
