#!/bin/sh

# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

NOW=$(date +%H-%M-%S)
TODAY=$(date +%d-%m-%Y)

MODE="$1"

# PACKAGE VARIABLES
PACKAGE="ts3server"
NAME="TeamSpeak 3 Server"

# BACKUP VARIABLES
TS3SERVER_BACKUP_DIRS="files logs"
TS3SERVER_BACKUP_FILES="ts3server.sqlitedb query_ip_whitelist.txt query_ip_blacklist.txt ts3server.ini ts3db_mysql.ini licensekey.dat"
TS3SERVER_BACKUP_NAME="ts3server_backup_${TODAY}_${NOW}"
TS3SERVER_BACKUP_SOURCE="/var/packages/ts3server/target/teamspeak3-server_linux"
TS3SERVER_BACKUP_DESTINATION="$2"
TS3SERVER_BACKUP_NAME_RESTORE="$3"

TS3Server_backup ()
{
	[ ! -d "$TS3SERVER_BACKUP_DESTINATION" ] && exit 1

	mkdir ${TS3SERVER_BACKUP_DESTINATION}/${TS3SERVER_BACKUP_NAME}

	for BACKUP_DIR in $TS3SERVER_BACKUP_DIRS; do
		cp -fr "${TS3SERVER_BACKUP_SOURCE}/${BACKUP_DIR}" "${TS3SERVER_BACKUP_DESTINATION}/${TS3SERVER_BACKUP_NAME}"
	done

	for BACKUP_FILE in $TS3SERVER_BACKUP_FILES; do
		cp -f "${TS3SERVER_BACKUP_SOURCE}/${BACKUP_FILE}" "${TS3SERVER_BACKUP_DESTINATION}/${TS3SERVER_BACKUP_NAME}"
	done

	exit 0
}

TS3Server_restore ()
{
	[ ! -d "$TS3SERVER_BACKUP_DESTINATION/${TS3SERVER_BACKUP_NAME_RESTORE}" ] && exit 1

	cp -fr ${TS3SERVER_BACKUP_DESTINATION}/${TS3SERVER_BACKUP_NAME_RESTORE}/* ${TS3SERVER_BACKUP_SOURCE}/

	exit 0
}

if [[ "$MODE" != "backup" && "$MODE" != "restore" ]]; then
	exit 1
fi

case $MODE in
	backup)
		(TS3Server_backup) > /dev/null 2>&1
	;;
	restore)
		(TS3Server_restore) > /dev/null 2>&1
	;;
esac
