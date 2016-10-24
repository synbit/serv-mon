#!/bin/bash

# Reference:
# nodetool's output represents "Status" and "State" in this order.
# Status values: U (up), D (down)
# State values: N (normal), L (leaving), J (joining), M (moving)

NODETOOL=$(which nodetool);
NODES_DOWN=$(${NODETOOL} --host localhost status | grep --count -E '^D[A-Z]');

if [[ ${NODES_DOWN} -gt 0 ]]; then
    output="CRITICAL - Nodes down: ${NODES_DOWN}";
    return_code=2;
elif [[ ${NODES_DOWN} -eq 0 ]]; then
    output="OK - Nodes down: ${NODES_DOWN}";
    return_code=0;
else
    output="UNKNOWN - Couldn't retrieve cluster information.";
    return_code=3;
fi

echo "${output}";
exit "${return_code}";
