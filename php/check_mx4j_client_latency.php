#!/usr/bin/php
<?php

$args = getopt("H:o:w:c:");

define('OK',0);
define('WARNING',1);
define('CRITICAL',2);
define('UNKNOWN',3);

$statuses = array('OK', 'WARNING', 'CRITICAL', 'UNKNOWN');

isset($args["H"]) ? $host = $args["H"] : call_user_func(function(){print "Missing mandatory argument: -H\n"; exit(4);});
isset($args["o"]) ? $operation = $args["o"] : call_user_func(function(){print "Missing mandatory argument: -o (-o read|write)\n"; exit(4);});

$mx4jUrl = array(
	 'write' => 'http://'.$host.':8081/mbean?template=identity&objectname=org.apache.cassandra.metrics%3Atype%3DClientRequest%2Cscope%3DWrite%2Cname%3DLatency',
	 'read' => 'http://'.$host.':8081/mbean?template=identity&objectname=org.apache.cassandra.metrics%3Atype%3DClientRequest%2Cscope%3DRead%2Cname%3DLatency'
);

function getCounters() {
	 global $operation, $statuses, $mx4jUrl;
	 $getUrl = file_get_contents($mx4jUrl[$operation]);
	 $xmlOut = new SimpleXMLElement($getUrl);

	 foreach ($xmlOut->Attribute as $attr) {
	 	 $innerAttr = $attr->attributes();
		 $tagAttr = array();

		 foreach ($innerAttr as $key => $value) {
		 	 $tagAttr[$key] = $value;
		 }

		 switch($tagAttr["name"]) {
		 	case "50thPercentile":
			     $_50thPercentile = $tagAttr["value"];
			case "75thPercentile":
			     $_75thPercentile = $tagAttr["value"];
			case "95thPercentile":
			     $_95thPercentile = $tagAttr["value"];
			case "99thPercentile":
			     $_99thPercentile = $tagAttr["value"];
			case "StdDev":
			     $StdDev = $tagAttr["value"];
		 }
	 }

	 $status = $statuses[0];

	 print $status."-50thPercentile=".$_50thPercentile.",75thPercentile=".$_75thPercentile.",95thPercentile=".
	       $_95thPercentile.",99thPercentile=".$_99thPercentile.",StdDev=".$StdDev.
	       "|_50thPercentile=".$_50thPercentile."us;"."_75thPercentile=".$_75thPercentile."us;".
	       "_95thPercentile=".$_95thPercentile."us;"."_99thPercentile=".$_99thPercentile."us;".
	       "StdDev=".$StdDev."us\n";

	 exit(OK);
}

if ($operation === "write") {
    getCounters();
}

else if ($operation === "read") {
    getCounters();
}

?>
