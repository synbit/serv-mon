#!/bin/bash

AWK=$(which awk);

$AWK -v userCSV=$1 '
BEGIN {
	split(userCSV,definedUsers,",")
}
{ FS = ":";
	if ($3 >= 1000 && $1 != "nobody") {
		existingUsers[j++] = $1;
	}
}
END {
	for (existinguser in existingUsers) {
		existanceFlag = "false";
		for (defineduser in definedUsers) {
			if (existingUsers[existinguser] == definedUsers[defineduser]) {
				existanceFlag = "true";
				break;
			}
		}
		if (existanceFlag == "false") {
			unexpectedUsers[k++] = existingUsers[existinguser];
		}
	}
	if (k!=0) {
		printf "WARNING - The following extra users were detected: ";
		for (unexpecteduser in unexpectedUsers) {
			if(a++)
				printf ",";
			printf unexpectedUsers[unexpecteduser];
		}
		printf "\n";
		exit 1;
	}
	else {
		printf "OK - All users in the system match with those specified.\n"
		exit 0;
	}
}' /etc/passwd
