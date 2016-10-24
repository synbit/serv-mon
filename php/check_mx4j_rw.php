#!/usr/bin/php
<?php

define('OK',0);
define('WARNING',1);
define('CRITICAL',2);
define('UNKNOWN',3);

$status = array("OK", "WARNING", "CRITICAL", "UNKNOWN");

$keyspacesToExclude = array(
    "system",
    "system_traces",
);

$countersToMonitor = array(
    "WriteCount",
    "ReadCount",
);

$args = getopt("H:");

isset($args["H"]) ? $host = $args["H"] : call_user_func(function(){print "Missing mandatory argument: -H (hostname)\n"; exit(4);});

$mx4jUrl = array(
    'nodeUrl' => 'http://'.$host.':8081?template=identity',
);

$getTables = file_get_contents($mx4jUrl['nodeUrl']);
$xmlTables = new SimpleXMLElement($getTables);
$tableXML = $xmlTables->xpath('//Domain[@name="org.apache.cassandra.db"]/MBean[@classname="org.apache.cassandra.db.ColumnFamilyStore"]/@objectname');

$perfData = array();

foreach ($tableXML as $data) {

    $objValue = explode(",", str_replace("org.apache.cassandra.db:","", $data));

    foreach ($objValue as $smth) {
        list($keyname, $keyvalue) = explode("=", $smth);

        if ($keyname == "keyspace") {
            $keyspace = $keyvalue;
        }
        else if ($keyname == "columnfamily") {
            $columnfamily = $keyvalue;
        }
    }

    if (in_array($keyspace, $keyspacesToExclude))
        continue;

    $content = file_get_contents(
        'http://'.$host.':8081/mbean?template=identity&objectname=org.apache.cassandra.db%3Atype%3DColumnFamilies%2Ckeyspace%3D'.$keyspace.'%2Ccolumnfamily%3D'.$columnfamily
    );

    $contentXML = new SimpleXMLElement($content);

    foreach ($contentXML->Attribute as $alfa) {

        $attributeName = "" . $alfa->attributes()->name;

        if (in_array($attributeName, $countersToMonitor))
            $perfData["{$keyspace}.{$columnfamily}.{$attributeName}"] = "" . $alfa->attributes()->value;
    }
}

print $status[0]." | ";

foreach ($perfData as $counter => $counterValue) {
    $counterPart = explode(".", $counter);
    $unit = strtolower(str_replace("Count", "", $counterPart[2]));
    print "{$counter}={$counterValue}{$unit}s;";
}

print "\n";

exit(0);

?>
