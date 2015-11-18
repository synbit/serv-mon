#!/bin/bash

AWK=$(which awk);

echo -ne "OK - Users: ";

$AWK '
{ FS = ":";
	if ($3 >= 1000 && $1 != "nobody") {
		if (a++)
			printf ",";
		printf("%s", $1);
	}
} END { printf "\n"; }' /etc/passwd;
