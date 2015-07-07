#!/bin/bash

# hddtemp runs as a deamon, and by default listens on
# TCP 7634 port, localhost.
# There is also:
# /usr/sbin/smartctl /dev/sda -a , but it requires root...

MYSQL=$(which mysql);
UNAME='mylogin';                                                                                                      
PASSWD='mypassword';                                                                            
DB='mydb';
SRV_ID=1;

# With -F you can specify the field seperator. Or like 
# I do here, can specify a REGEX. This helps if you want
# to specify multiple delimiters.

nc 127.0.0.1 7634 | awk -F'[|]' '{
	disk1 = $2;
	disk1_temp = $4;
	disk2 = $7;
	disk2_temp = $9;
}
END {
print "INSERT INTO eulinx.disk_stat(srv_id,disk1,disk1_temp,disk2,disk2_temp,last_check) VALUES("'\"${SRV_ID}\"'",""'\''"disk1"'\''"","disk1_temp",""'\''"disk2"'\''"","disk2_temp",NOW());"
}' | tee /dev/stderr | ${MYSQL} ${DB} --user=${UNAME} --password=${PASSWD};
