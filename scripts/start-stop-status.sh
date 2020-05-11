#!/bin/sh

# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

###BEGIN INIT INFO########################
#
# start-stop-status
# Starts, stops the TS3 server and
# reports status to the package manager
#
###END INIT INFO##########################

# PACKAGE
PACKAGE="ts3server"
NAME="TeamSpeak 3 Server"
PKGDEST=$(readlink "/var/packages/${PACKAGE}/target")
UIDEST="/usr/syno/synoman/webman/3rdparty/$PACKAGE"
TMP_DIR="${PKGDEST}/../../@tmp"

# COMMON PACKAGE VARIABLES
COMMANDLINE_PARAMETERS=$(cat $PKGDEST/ui/etc/config | grep Startparameter= | sed -e 's|Startparameter=||g')
BINARYPATH="/var/packages/${PACKAGE}/target/teamspeak3-server_linux"
BINARYNAME="ts3server"
TOKENDIR="${BINARYPATH}/logs"
LOG_DIR="${BINARYPATH}/logs"
LOG=$(ls -t ${LOG_DIR} | grep "ts3server_*" | head -n 2) # Only display the newest log
TS3SERVER_PID="${BINARYPATH}/ts3server.pid"
TS3SERVER_LOG="${TMP_DIR}/ts3server.log"

# MISCELLANEOUS
DSMMAJOR=$(get_key_value /etc.defaults/VERSION majorversion)
DSMMINOR=$(get_key_value /etc.defaults/VERSION minorversion)
DSMBUILD=$(get_key_value /etc.defaults/VERSION buildnumber)

# PS COMMAND && GREP COMMAND DSM 5 != DSM 6
if [ "${DSMMAJOR}" -eq "5" ]; then
	PSCOMMAND="ps"
	GREPCOMMAND="grep"
else
	PSCOMMAND="ps -x"
	GREPCOMMAND="grep -w"
fi

# EXPORT THE TEAMSPEAK LIBRARY PATH
export LD_LIBRARY_PATH="${BINARYPATH}"

# DSM language based messages
source "$(dirname $0)"/lang.sh

TS3SERVER_START ()
{
	[ ! -e "$UIDEST" ] && ln -s $PKGDEST/ui "$UIDEST"
	
	if [[ -e "$TS3SERVER_PID" && ! -z "$(cat $TS3SERVER_PID)" ]]; then
		if ( kill -0 $(cat $TS3SERVER_PID) 2> /dev/null ); then
			echo "$ALREADY_RUNNING"
			exit 1
		fi
	else
		# DSM 6 fix for empty ts3server.pid.
		PID=$($PSCOMMAND | grep -v grep | $GREPCOMMAND ./${BINARYNAME} | awk '{print $1}')
		if ( kill -0 $PID 2> /dev/null ); then
			echo "$ALREADY_RUNNING"
			echo $PID > $TS3SERVER_PID
			exit 1
		fi
	fi

	cd ${BINARYPATH} && ./${BINARYNAME} ${COMMANDLINE_PARAMETERS} > /dev/null &
	
	if [ "${DSMMAJOR}" -eq "5" ]; then
		PID=$!
	else
		PID=$($PSCOMMAND | grep -v grep | $GREPCOMMAND ./${BINARYNAME} | awk '{print $1}')
	fi

	echo $PID > $TS3SERVER_PID

	TokenMessage

	exit 0
}

TS3SERVER_STOP ()
{
	if [ -e "$TS3SERVER_PID" ]; then
		if ( kill -TERM $(cat $TS3SERVER_PID) 2> /dev/null ); then
			c=1
			while [ "$c" -le 300 ]; do
				if ( kill -0 $(cat $TS3SERVER_PID) 2> /dev/null ); then
					sleep 1
				else
					break
				fi
				c=$(($c+1))
			done
		fi

		if ( kill -0 $(cat $TS3SERVER_PID) 2> /dev/null ); then
			echo "$HARD_SHUTDOWN"
			kill -KILL $(cat $TS3SERVER_PID)
		fi
		rm $TS3SERVER_PID
		echo "$SERVER_STOPED"
	fi
	exit 0
}

TS3SERVER_STATUS ()
{	
	if [[ -e "$TS3SERVER_PID" && ! -z "$(cat $TS3SERVER_PID)" ]]; then
		if ( kill -0 $(cat $TS3SERVER_PID) 2> /dev/null ); then
			# Server is online
			exit 0
		else
			# Server is offline
			exit 1
		fi
	else
		# DSM 6 fix for empty ts3server.pid.
		PID=$($PSCOMMAND | grep -v grep | $GREPCOMMAND ./${BINARYNAME} | awk '{print $1}')
		if ( kill -0 $PID 2> /dev/null ); then
			echo $PID > $TS3SERVER_PID
			# Server is online
			exit 0
		else
			# Server is offline
			exit 1
		fi
	fi
}

TS3SERVER_LOG ()
{
	cd ${LOG_DIR} && cat ${LOG} | sort > $TS3SERVER_LOG
	echo "$TS3SERVER_LOG"
	exit 0
}

TokenMessage ()
{
	if [ ! -f ${TOKENDIR}/TOKEN ]; then

		# Wait till the server created the db and logfiles
		sleep 30

		for LOGFILE in $(ls $TOKENDIR); do
			if [ "$(cat ${TOKENDIR}/${LOGFILE} | grep token | sed -n -e 's/^.*token=//p')" ]; then
				local TOKEN=$(cat ${TOKENDIR}/${LOGFILE} | grep token | sed -n -e 's/^.*token=//p')
			fi
		done

		[ -z $TOKEN ] && local TOKEN="NO TOKEN AVAILABLE"

		if [ $TOKEN != "NO TOKEN AVAILABLE" ]; then
			local TITLE="TeamSpeak 3 Server Admin Token"
			local MESSAGE="Admin Token: $TOKEN"
			# Send a status message to the DSM Notify Center
			synodsmnotify @administrators "$TITLE" "$MESSAGE"
		fi

		echo $TOKEN > ${TOKENDIR}/TOKEN
	fi
}

case $1 in
	start)
		TS3SERVER_START
	;;
	stop)
		TS3SERVER_STOP
	;;
	status)
		TS3SERVER_STATUS
	;;
	log)
		TS3SERVER_LOG
	;;
	*)
		exit 1
	;;
esac
