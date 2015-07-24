#!/bin/bash

# Full path of this script:
DIR=$(dirname "${BASH_SOURCE[0]}");

# Load config:
source ${DIR}/script.conf/cpuStats.conf;

MYSQL=$(which mysql); 
HOSTNAME=$(hostname);

/usr/bin/mpstat -P ALL 1 1 | awk '
{
	if (NR == 11){usr = $3; nice = $4; sys = $5; iowait = $6; irq = $7; soft = $8; steal = $9; guest = $10; idle = $11; TotalUsed = usr+nice+sys+iowait+irq+soft+steal+guest;}
	else if (NR == 12){cpu0Used = $3+$4+$5+$6+$7+$8+$9+$10; cpu0Idle = $11;}
	else if (NR == 13){cpu1Used = $3+$4+$5+$6+$7+$8+$9+$10; cpu1Idle = $11;}
	else if (NR == 14){cpu2Used = $3+$4+$5+$6+$7+$8+$9+$10; cpu2Idle = $11;}
	else if (NR == 15){cpu3Used = $3+$4+$5+$6+$7+$8+$9+$10; cpu3Idle = $11;}
}
END{

print "INSERT INTO eulinx.server_cpu(srv_id,srv_name,cores,used_total,idle,usr,nice,sys,iowait,irq,soft,steal,guest,cpu0used,cpu0idle,cpu1used,cpu1idle,cpu2used,cpu2idle,cpu3used,cpu3idle,last_check) VALUES("'\"${SRV_ID}\"'","'\"\'${HOSTNAME}\'\"'","'\"${CORES}\"'","TotalUsed","idle","usr","nice","sys","iowait","irq","soft","steal","guest","cpu0Used","cpu0Idle","cpu1Used","cpu1Idle","cpu2Used","cpu2Idle","cpu3Used","cpu3Idle",NOW());"
}' | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
