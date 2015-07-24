#!/bin/bash

# Full path of this script:
DIR=$(dirname "${BASH_SOURCE[0]}");

# Load config:
source ${DIR}/script.conf/upsdata.conf;

mysql=`which mysql`;

/sbin/apcaccess | awk '

/^(STATUS|TONBATT|BCHARGE|ITEMP|LINEV|BATTV|LINEFREQ)/ {stat[$1]=$3}
 
END {
		print "INSERT INTO eulinx.ups_stat(ups_id,status,sec_on_batt,batt_level,temp,vin,vout,fin,last_check) VALUES("'\"${UPS_ID}\"'",""'"'"'"stat["STATUS"]"'\'',""'\''"stat["TONBATT"]"'\'',""'\''"stat["BCHARGE"]"'\'',""'\''"stat["ITEMP"]"'\'',""'\''"stat["LINEV"]"'\'',""'\''"stat["BATTV"]"'\'',""'\''"stat["LINEFREQ"]"'\'',NOW());"
}' | tee /dev/stderr | ${mysql} ${db} --user=${uname} --password=${passwd};
