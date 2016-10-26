#!/usr/bin/php
<?php

define('OK',0);
define('WARNING',1);
define('CRITICAL',2);
define('UNKNOWN',3);

$args = getopt("H:");

isset($args["H"]) ? $host = $args["H"] : call_user_func(function(){print "Missing mandatory argument: -H (hostname)\n"; exit(4);});

$mx4jUrl = 'http://' . $host . ':8081/getattribute?objectname=org.apache.cassandra.net:type=FailureDetector&attribute=SimpleStates&format=map&template=viewmap&template=identity';

$getContent = file_get_contents($mx4jUrl);
$xmlContent = new SimpleXMLElement($getContent);

$output = '';
$down = 0;
$exit_status = "OK";
$exit_code = OK;

foreach ($xmlContent->xpath('//Element') as $line) {
        $output .= "{$line['key']}:{$line['element']}, ";
        if ("{$line['element']}" != "UP") {
                $down++;
        }
}

if ($down > 0) {
        $exit_status = "CRITICAL";
        $exit_code = CRITICAL;
}

echo "$exit_status - Nodes unavailable: $down, Cluster Status: $output\n";
exit($exit_code);

?>
