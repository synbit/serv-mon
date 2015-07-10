#!/bin/bash

# Load config:
source script.conf/bwStats.conf;

MYSQL=$(which mysql);
HOSTNAME=$(hostname);
IFSTAT=$(which ifstat);

# Collect the data:
${IFSTAT} -w -i eth0,lo 1 1 | awk '
{ 
	if(NR == 3)
	{ 
		eth0_in = $1;
		eth0_out = $2;
		lo_in = $3;
		lo_out = $4;
	} 
}
END {

print "INSERT INTO eulinx.server_bandwidth(srv_id,srv_name,lo_in,lo_out,eth0_in,eth0_out,last_check) VALUES("'\"${SRV_ID}\"'","'\"\'${HOSTNAME}\'\"'","lo_in","lo_out","eth0_in","eth0_out",NOW());"
}' | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
