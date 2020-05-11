#!/bin/sh

# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

LANG_FILE="$(dirname "$0")/lang/$SYNOPKG_DSM_LANGUAGE"
if [ -f "${LANG_FILE}" ]; then
	source "${LANG_FILE}"
else
	source "$(dirname "$0")/lang/enu"
fi
