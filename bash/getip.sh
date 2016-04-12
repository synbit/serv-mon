#!/bin/bash

curl -sS http://checkip.dns.he.net | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}';
