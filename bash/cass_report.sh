#!/bin/bash

which cassandra || echo "UNKNOWN - Apache Cassandra is not installed on this server" && exit 3;

offset=$1;

if [[ -z ${offset} ]]; then
        echo "UNKNOWN - Please provide ARG1: number of rotated logs to inspect";
        exit 3;
fi

cd /var/log/cassandra;

for ((x=1; x<=${offset}; x++)); do
    log[$x]=$(date +%Y-%m-%d -d "-${x} days");
    echo "[system.log.${log[$x]}]";
    echo -ne "\tNumber of lines : ";
    wc -l system.log.${log[$x]};
    echo -ne "\tMsg dropped (times) : ";
    grep  "dropped in last 5000 ms" system.log.${log[$x]} | awk -F "[, ]" '{print $4}' | uniq | wc -l;
    echo -ne "\t Total msg dropped : ";
    grep "dropped in last 5000 ms" system.log.${log[$x]} | awk -F "[, ]" '{msg+=$17}END{if(!msg){print "N/A"}else{print msg}}';
    echo -ne "\tNumber of GC pauses : ";
    grep --count GC system.log.${log[$x]};
    echo -ne "\t ParNew(avg_duration/num_pauses) : ";
    grep ParNew system.log.${log[$x]} | awk '{logs++; GC+=$11}END{if(!logs){print "N/A"}else{print GC/NR"/"logs}}';
    echo -ne "\t ConcurrentMarkSweep(avg_duration/num_pauses) : ";
    grep ConcurrentMarkSweep system.log.${log[$x]} | awk '{logs++; GC+=$11}END{if(!logs){print "N/A"}else{print GC/NR"/"logs}}';
done
