#!/bin/bash

# Reference:
# nodetool's output represents "Status" and "State" in this order.
# Status values: U (up), D (down)
# State values: N (normal), L (leaving), J (joining), M (moving)

which cassandra || echo "UNKNOWN - Apache Cassandra is not installed on this server" && exit 3;

NODETOOL_OUTPUT=$(nodetool status 2> /dev/null);
NODETOOL_EXIT_CODE=$?;
NODES_DOWN=$(echo "${NODETOOL_OUTPUT}" | grep --count -E '^D[A-Z]');

if [[ ${NODETOOL_EXIT_CODE} -ne 0 ]]; then
        output="UNKNOWN - Couldn't retrieve cluster information. Maybe nodetool was executed on a box where C* is down?";
        return_code=3;
elif [[ ${NODES_DOWN} -gt 0 ]]; then
        output="CRITICAL - Nodes down: ${NODES_DOWN}";
        return_code=2;
elif [[ ${NODES_DOWN} -eq 0 ]]; then
        output="OK - Nodes down: ${NODES_DOWN}";
        return_code=0;
fi

echo "${output}";
exit "${return_code}";
