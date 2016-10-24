#!/bin/bash

: <<'COMMENT'
In order for this to work the nagios user must be able to run certain commands as the cassandra user.
In the sudoers.d directory the following must be saved in a file with the right permissions:

nagios ALL=(cassandra)NOPASSWD:/usr/bin/jps
nagios ALL=(cassandra)NOPASSWD:/usr/bin/jstat -[a-z][a-z]* [0-9][0-9]*

COMMENT

OK=0;
WARNING=1;
CRITICAL=2;
UNKNOWN=3;
statuses=( OK WARNING CRITICAL UNKNOWN );

while getopts "o:h" opt
do case "${opt}" in
       o)
	   option=$OPTARG;
	   ;;
       h|\?)
	   echo -e "check_cass_gc.sh : Runs jstat as 'cassandra' and retrieves information about heap space specific generations.";
	   echo -e "About specific jstat options and their specific output and meaning check here:";
	   echo -e "\t http://docs.oracle.com/javase/7/docs/technotes/tools/share/jstat.html";
	   echo -e "Options:";
	   echo -e "\t -o : jstat specific option (currently only works for 'gcutil')."
	   echo -e "\t -h : Display this help message.";
	   exit;
	   ;;
   esac
done

if [[ -z ${option} ]]; then
    echo -e 'Error: Missing mandatory argument -o <jstat_option>.';
    echo -e "\n";
    $0 -h;
    exit ${UNKNWON};
fi

pid=$(/usr/bin/sudo -u cassandra /usr/bin/jps | awk '/Cassandra/ {print $1}');

if [[ -z ${pid} ]]; then
    echo -e 'Error: could not get PID for cassandra service.';
    echo -e "\n";
    $0 -h;
    exit ${UNKNOWN};
fi

: <<'COMMENT'
'jstat -gcutil' output:
        S0, S1, E, O, P, YGC, YGCT, FGC, FGCT, GCT
COMMENT

stats=( $(/usr/bin/sudo -u cassandra /usr/bin/jstat -${option} ${pid} | tail -1) );

if [[ ${#stats[@]} ]]; then
    return_status=${statuses[3]};
    return_code=${UNKNOWN};
fi

surv0=${stats[0]};
surv1=${stats[1]};
eden=${stats[2]};
old=${stats[3]};
perm=${stats[4]};

return_code=${OK};

echo "${statuses[0]} - S0=${surv0}%,S1=${surv1}%,E=${eden}%,O=${old}%,P=${perm}%|Survivor0=${surv0}%;Survivor1=${surv1}%;Eden=${eden}%;Old=${old}%;PermGen=${perm}%;";

exit $return_code;

