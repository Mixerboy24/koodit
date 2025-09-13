<?php

// Is this live? Set to true or false
$active = true;

// Put the details of your cPanel DNS cluster here that you want DA to update on zone writes
// You can add more than 2

$ns = array();
$ns["ns1"] = array( "host" => "ns1.DOMAIN.TLD",'rootpw' => "ROOT PWD");
$ns["ns2"] = array( "host" => "ns2.DOMAIN.TLD",'rootpw' => "ROOT PWD");

//enable logging
$logging = false;

