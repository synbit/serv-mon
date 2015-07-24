#!/bin/bash

# Full path of this script:
DIR=$(dirname "${BASH_SOURCE[0]}");

# Load config:
source ${DIR}/script.conf/powerUsage.conf;

# The current UPS model: Smart-UPS 700. This is 700 VA (P=V*I Watts).
# Watts = (Precentage*700)*1/sqrt(2), to convert Peak-to-Peak to RMS.

MYSQL=$(which mysql);

# We are looking for "LOADPCT", currently on line 13:
/sbin/apcaccess | awk '
{
	if (NR == 13)
	{
		load = $3;
	}
	
	watts = load*7/sqrt(2);
}
END {
	print "INSERT INTO eulinx.ups_power_stat(ups_id,units_attached,load_percent,watts,last_check) VALUES ("'\"${UPS_ID}\"'","'\"${UNITS_ATTACHED}\"'","load","watts",NOW());"
}' | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
