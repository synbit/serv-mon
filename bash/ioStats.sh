#!/bin/bash

# Full path of this script:
DIR=$(dirname "${BASH_SOURCE[0]}");

# Load config:
source ${DIR}/script.conf/ioStats.conf;

IOSTAT=$(which iostat);
MYSQL=$(which mysql);
HOSTNAME=$(hostname);

${IOSTAT} -d | awk '
{
	if (NR == 4)
	{
		dev1 = $1;
		dev1_tps = $2;
		dev1_rps = $3;
		dev1_wps = $4;
	}
	else if (NR == 5)
	{
		dev2 = $1;
		dev2_tps = $2;
		dev2_rps = $3;
		dev2_wps = $4;
	}
	else if (NR == 6)
	{
		dev3 = $1;
		dev3_tps = $2;
		dev3_rps = $3;
		dev3_wps = $4;
	}
	else if (NR == 7)
	{
		dev4 = $1;
		dev4_tps = $2;
		dev4_rps = $3;
		dev4_wps = $4;
	}
	else if (NR == 8)
	{
		dev5 = $1;
		dev5_tps = $2;
		dev5_rps = $3;
		dev5_wps = $4;
	}
	else if (NR == 9)
	{
		dev6 = $1;
		dev6_tps = $2;
		dev6_rps = $3;
		dev6_wps = $4;
	}
}
END {
	print "INSERT INTO eulinx.server_io(srv_id,dev1,dev1_tps,dev1_rps,dev1_wps,dev2,dev2_tps,dev2_rps,dev2_wps,dev3,dev3_tps,dev3_rps,dev3_wps,dev4,dev4_tps,dev4_rps,dev4_wps,dev5,dev5_tps,dev5_rps,dev5_wps,dev6,dev6_tps,dev6_rps,dev6_wps,last_check) VALUES("'\"${SRV_ID}\"'",""'"'"'"dev1"'"'"'"","dev1_tps","dev1_rps","dev1_wps",""'"'"'"dev2"'"'"'"","dev2_tps","dev2_rps","dev2_wps",""'"'"'"dev3"'"'"'"","dev3_tps","dev3_rps","dev3_wps",""'"'"'"dev4"'"'"'"","dev4_tps","dev4_rps","dev4_wps",""'"'"'"dev5"'"'"'"","dev5_tps","dev5_rps","dev5_wps",""'"'"'"dev6"'"'"'"","dev6_tps","dev6_rps","dev6_wps",NOW());"
}' | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
