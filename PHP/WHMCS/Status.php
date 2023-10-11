<?php

// WHMCS Server Status Monitoring Endpoint. Example: Multicraft, AMP..
// Add this script WebRoot Folder. -> (https://Domain.tdl/Status.php)
// Example Multicraft: Add this to Multicraft Webroot Folder (/var/www/html/Multicraft). -> (https://domain.tdl/Multicraft/status.php)
// Add Endpoint URL (https://Domain.tdl/Status.php) WHMCS -> System Settings -> Servers -> Select Server -> Edit -> Server Status Address

// Copyright: WHMCS Limited

error_reporting(0);

$action = (isset($_GET['action'])) ? $_GET['action'] : '';

if ($action=="phpinfo") {

    //phpinfo();

} else {

    $load = file_get_contents("/proc/loadavg");
    $load = explode(' ',$load);
    $load = $load[0];
    if (!$load && function_exists('exec')) {
        $reguptime=trim(exec("uptime"));
        if ($reguptime) if (preg_match("/, *(\d) (users?), .*: (.*), (.*), (.*)/",$reguptime,$uptime)) $load = $uptime[3];
    }

    $uptime_text = file_get_contents("/proc/uptime");
    $uptime = substr($uptime_text,0,strpos($uptime_text," "));
    if (!$uptime && function_exists('shell_exec')) $uptime = shell_exec("cut -d. -f1 /proc/uptime");
    $days = floor($uptime/60/60/24);
    $hours = str_pad($uptime/60/60%24,2,"0",STR_PAD_LEFT);
    $mins = str_pad($uptime/60%60,2,"0",STR_PAD_LEFT);
    $secs = str_pad($uptime%60,2,"0",STR_PAD_LEFT);

    $phpver = phpversion();
    $mysqlver = (function_exists("mysql_get_client_info")) ? mysql_get_client_info() : '-';
    $zendver = (function_exists("zend_version")) ? zend_version() : '-';

    echo "<load>$load</load>\n";
    echo "<uptime>$days Days $hours:$mins:$secs</uptime>\n";

?>
