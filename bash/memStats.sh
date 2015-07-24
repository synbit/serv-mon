#!/bin/bash

# Full path of current script:
DIR=$(dirname "${BASH_SOURCE[0]}");

# Load config:
source ${DIR}/script.conf/memStats.conf;

MYSQL=$(which mysql);
HOSTNAME=$(hostname);

awk ' { 

if ($1 ~ "MemTotal")
	total += $2;
else if ($1 ~ "MemFree")
	free += $2;
else if ($1 ~ "Buffers")
	buffers += $2;
else if ($1 ~ "Cached")
	cache += $2;

used = total-free-buffers-cache;

} 

END {

print "INSERT INTO eulinx.server_memory(srv_id,srv_name,mem_total,mem_free,mem_buffers,mem_cache,mem_used,last_check) VALUES("'\"${SRV_ID}\"'","'\"\'${HOSTNAME}\'\"'","total","free","buffers","cache","used",NOW());"

}' < /proc/meminfo | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
