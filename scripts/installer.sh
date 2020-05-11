#!/bin/sh

# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

# PACKAGE VARIABLES
PACKAGE="ts3server"
NAME="TeamSpeak 3 Server"

NOW=$(date +%H-%M-%S)
TODAY=$(date +%d-%m-%Y)

# COMMON PACKAGE VARIABLES
TS3SERVER_BIN="teamspeak3-server_linux"
TS3SERVER_VER="3.10.2"
TS3SERVER_ARCH=$([ "${pkgwizard_arch_amd64}" == "true" ] && echo "amd64" || echo "x86")
TS3SERVER_DOWNLOAD_BASE_URL="http://files.teamspeak-services.com/releases/server"
TS3SERVER_DOWNLOAD_URL="${TS3SERVER_DOWNLOAD_BASE_URL}/${TS3SERVER_VER}/${TS3SERVER_BIN}_${TS3SERVER_ARCH}-${TS3SERVER_VER}.tar.bz2"
TS3SERVER_DOWNLOAD_FILE="$(basename ${TS3SERVER_DOWNLOAD_URL})"
TS3SERVER_HELPER_VAR=${TS3SERVER_DOWNLOAD_FILE%-$TS3SERVER_VER.tar.bz2}
TS3SERVER_BACKUP_DIR="ts3server_backup_files"
TS3SERVER_INSTALL_FILES="ts3server_install_files"
TS3SERVER_BINARYNAME="ts3server"

# BACKUP VARIABLES
TS3SERVER_BACKUP_DIRS="files logs"
TS3SERVER_BACKUP_FILES="ts3server.sqlitedb query_ip_whitelist.txt query_ip_blacklist.txt ts3server.ini ts3db_mysql.ini licensekey.dat"
TS3SERVER_BACKUP_PATH="${SYNOPKG_PKGDEST%/${PACKAGE}}/.${PACKAGE}_backup"
TS3SERVER_BACKUP_NAME="ts3server_backup_${TODAY}_${NOW}"

# MISCELLANEOUS
DSMMAJOR=$(get_key_value /etc.defaults/VERSION majorversion)
DSMMINOR=$(get_key_value /etc.defaults/VERSION minorversion)
DSMBUILD=$(get_key_value /etc.defaults/VERSION buildnumber)
UIDEST="/usr/syno/synoman/webman/3rdparty/$PACKAGE"

# DSM language based messages
source "$(dirname $0)"/lang.sh

preinst ()
{
	# Nothing to be done here if we upgrade
	if [ "$SYNOPKG_PKG_STATUS" == "UPGRADE" ]; then
		exit 0
	fi
	
	# Create a temp dir for the install files!
	[ ! -d "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}" ] && mkdir -p "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	# Download the TeamSpeak3 Server
	wget "${TS3SERVER_DOWNLOAD_URL}" -P "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	# Check if the download was successfully
	if [ ! -e "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_DOWNLOAD_FILE}" ]; then
		echo "$DOWNLOAD_ERROR"
		exit 1
	fi
	
	# Decompress the downloaded TeamSpeak3 Server
	tar -xjf "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_DOWNLOAD_FILE}" -C "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	if [ $? != 0 ]; then
		echo "$EXTRACT_ERROR"
		exit 1
	fi
	
	exit 0
}

postinst ()
{	
	# Nothing to be done here if we upgrade
	if [ "$SYNOPKG_PKG_STATUS" == "UPGRADE" ]; then
		exit 0
	fi
	
	# Copy the downloaded TeamSpeak3 Server
	# packages are moved by synology before post install.
	cp -fr ${SYNOPKG_PKGDEST}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_HELPER_VAR}/* ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}

	# Accept TeamSpeak3 License
	if [ "$pkgwizard_licence_accept" == "true" ]; then
		touch ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/.ts3server_license_accepted
	fi

	# create a file with the installed ARCH (x86 or amd64)
	touch ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/INSTALLED_ARCH_${TS3SERVER_ARCH}
	
	# Delete the install files
	rm -r ${SYNOPKG_PKGDEST}/${TS3SERVER_INSTALL_FILES}
	
	[ ! -e "$UIDEST" ] && ln -s ${SYNOPKG_PKGDEST}/ui "$UIDEST"

	exit 0
}

preuninst ()
{
	# Nothing to be done here if we upgrade
	if [ "$SYNOPKG_PKG_STATUS" == "UPGRADE" ]; then
		exit 0
	fi

	if [ "$pkgwizard_backup_data" == "true" ]; then
	
		[ ! -d "${TS3SERVER_BACKUP_PATH}/${TS3SERVER_BACKUP_NAME}" ] && mkdir -p "${TS3SERVER_BACKUP_PATH}/${TS3SERVER_BACKUP_NAME}"

		# Skip all standard dirs and save only importent/user dirs
		for BACKUP_DIR in $TS3SERVER_BACKUP_DIRS; do
			cp -fr "${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/${BACKUP_DIR}" "${TS3SERVER_BACKUP_PATH}/${TS3SERVER_BACKUP_NAME}"
		done
		
		# Skip all standard files and save only importent/user files
		for BACKUP_FILE in $TS3SERVER_BACKUP_FILES; do
			cp -f "${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/${BACKUP_FILE}" "${TS3SERVER_BACKUP_PATH}/${TS3SERVER_BACKUP_NAME}"
		done
	fi

	exit 0
}

postuninst ()
{
	# Nothing to be done here if we upgrade
	if [ "$SYNOPKG_PKG_STATUS" == "UPGRADE" ]; then
		exit 0
	fi
	
	if [ "$pkgwizard_backup_data" == "true" ]; then
		echo "$BACKUP_SUCCESSFULL"
	fi
	
	[ -e "$UIDEST" ] && rm -f "$UIDEST"
	
	exit 0
}

preupgrade ()
{
	# If we come from Package Version <= 3.0.13.8-2 we need to change the ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN} folder (teamspeak3-server_linux-x86 --> teamspeak3-server_linux)
	if [ -d ${SYNOPKG_PKGDEST}/teamspeak3-server_linux-x86 ]; then
		mv -f ${SYNOPKG_PKGDEST}/teamspeak3-server_linux-x86 ${SYNOPKG_PKGDEST}/teamspeak3-server_linux
	fi

	# Check if the Package is upgradeable
	if [ ! -d "${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}" ]; then
		echo "$UPGRADE_ERROR"
		exit 1
	fi
	
	# When upgrading, we need to backup the config and server files into a temporary dir!
	[ ! -d "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_BACKUP_DIR}" ] && mkdir -p "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_BACKUP_DIR}"
	
	# Create a temp dir for the install files!
	[ ! -d "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}" ] && mkdir -p "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	# Download the TeamSpeak3 Server
	wget "${TS3SERVER_DOWNLOAD_URL}" -P "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	# Check if the download was successfully
	if [ ! -e "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_DOWNLOAD_FILE}" ]; then
		echo "$DOWNLOAD_ERROR"
		exit 1
	fi
	
	# Decompress the downloaded TeamSpeak3 Server
	tar -xjf "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_DOWNLOAD_FILE}" -C "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_INSTALL_FILES}"
	
	if [ $? != 0 ]; then
		echo "$EXTRACT_ERROR"
		exit 1
	fi
	
	# Skip all standard dirs and save only importent/user dirs
	for BACKUP_DIR in $TS3SERVER_BACKUP_DIRS; do
		cp -fr "${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/${BACKUP_DIR}" "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_BACKUP_DIR}"
	done
	
	# Skip all standard files and save only importent/user files
	for BACKUP_FILE in $TS3SERVER_BACKUP_FILES; do
		cp -f "${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/${BACKUP_FILE}" "${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_BACKUP_DIR}"
	done
	
	# Backup the ui config
	cp -f ${SYNOPKG_PKGDEST}/ui/etc/config ${SYNOPKG_PKGINST_TEMP_DIR}/${TS3SERVER_BACKUP_DIR}
	
	exit 0
}

postupgrade ()
{
	# Copy the downloaded TeamSpeak3 Server
	# packages are moved by synology before post upgrade.
	cp -fr ${SYNOPKG_PKGDEST}/${TS3SERVER_INSTALL_FILES}/${TS3SERVER_HELPER_VAR}/* ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}
	
	# Restore back the ui config
	mv -f ${SYNOPKG_PKGDEST}/${TS3SERVER_BACKUP_DIR}/config ${SYNOPKG_PKGDEST}/ui/etc/
	
	# Restore back the config and server dirs/files!
	cp -fr ${SYNOPKG_PKGDEST}/${TS3SERVER_BACKUP_DIR}/* ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/

	# Accept TeamSpeak3 License
	if [ ! -f ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/.ts3server_license_accepted ]; then
		if [ "$pkgwizard_licence_accept" == "true" ]; then
			touch ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/.ts3server_license_accepted
		fi
	fi

	# create a file with the installed ARCH (x86 or amd64)
	touch ${SYNOPKG_PKGDEST}/${TS3SERVER_BIN}/INSTALLED_ARCH_${TS3SERVER_ARCH}

	# Remove the temporary dir
	rm -r ${SYNOPKG_PKGDEST}/${TS3SERVER_BACKUP_DIR}
	
	# Delete the install files
	rm -r ${SYNOPKG_PKGDEST}/${TS3SERVER_INSTALL_FILES}
	
	[ ! -e "$UIDEST" ] && ln -s ${SYNOPKG_PKGDEST}/ui "$UIDEST"
	
	exit 0
}
