#!/usr/local/bin/php
<?php
// Script to manage DNS zones on a cPanel DNS cluster from a DA server
//
// Version 2
//
// To do:
// - DONE multi curl calls to write to NS
// - DONE comparison engine to handle edits/adds/deletes in a better way
// - Handle SOA record, and TTL's instead of setting them to 300

// Include details of DNS cluster servers
include('dns_write_post_config.php');

// Get all the variables from ENV, have to do it this way as $_ENV will be empty on many systems
$recs_domain = getenv('DOMAIN');

if(getenv('A') != ''){
  $recs_a = explode("&",getenv('A'));
}else{
  $recs_a = false;
}

if(getenv('AAAA') != ''){
  $recs_aaaa = explode("&",getenv('AAAA'));
}else{
  $recs_aaaa = false;
}

$recs_mx = explode("&",getenv('MX_FULL'));
$recs_txt = explode("&",getenv('TXT'));

if(getenv('CNAME') != ''){
  $recs_cname = explode("&",getenv('CNAME'));
}else{
  $recs_cname - false;
}

$recs_ns = explode("&",getenv('NS'));

if(getenv('SRV') != ''){
  $recs_srv = explode("&",getenv('SRV'));
}else{
  $recs_srv = false;
}

$recs_domip = getenv('DOMAIN_IP');

// array to hold all records from DA zone
$da_clean_arr = array();

// =================================================================
// ### DKIM-RAAKADATAN KORJAUS ###
// =================================================================
// Haetaan raaka TXT-data
$raw_txt_string = getenv('TXT');

// Etsitään, onko datassa lyhyt DKIM-nimi.
if (preg_match('/(x\._domainkey)=/', $raw_txt_string, $matches)) {

    $short_name = $matches[1];
    $full_name = $short_name . '.' . $recs_domain . '.';

    // 1. KORJATAAN NIMI
    $corrected_txt_string = str_replace($short_name . '=', $full_name . '=', $raw_txt_string);

    // 2. PUHDISTETAAN ITSE DKIM-DATA API:a varten
    // Etsitään koko DKIM-tietue (nimi ja data)
    if (preg_match('/' . preg_quote($full_name, '/') . '=\( (.*) \)/s', $corrected_txt_string, $data_matches)) {

        $dirty_data = $data_matches[1]; // Kaikki sulkujen sisältä

        // Poistetaan lainausmerkit ja kaikki whitespace-merkit (välilyönnit, rivinvaihdot, tabit)
        $clean_data = str_replace(array('"', "\t", "\n", "\r", " "), '', $dirty_data);

        // Rakennetaan tietue uudelleen puhtaalla datalla
        $final_record_part = $full_name . '=' . '"' . $clean_data . '"';

        // Korvataan vanha, sotkuinen tietue kokonaan uudella, puhtaalla versiolla
        $corrected_txt_string = preg_replace('/' . preg_quote($full_name, '/') . '=\( (.*) \)/s', $final_record_part, $corrected_txt_string);
    }

    // Ylikirjoitetaan ympäristömuuttuja ja paikallinen muuttuja
    putenv("TXT=" . $corrected_txt_string);
    $recs_txt = explode("&", $corrected_txt_string);

    if($logging == true){
        file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "DKIM NAME CORRECTED: From '" . $short_name . "' to '" . $full_name . "'. DATA CLEANED.\n", FILE_APPEND);
    }
}
// =================================================================
// ### DKIM-RAAKADATAN KORJAUS ###
// =================================================================

// Build A records array
foreach ($recs_a as $rec_key => $rec_val){
  // Split the record on =
  $rec_arr = explode("=",$rec_val);
  // DA only shows host, so build them to FQDN for comparison later
  if (strpos($rec_arr[0], $recs_domain) !== false) {
    // do nothing
  }else{
    $rec_arr[0] = $rec_arr[0].".".$recs_domain.".";
  }
  $recs_a[$rec_key] = array($rec_arr[0],$rec_arr[1]);
  $da_clean_arr[] = array('type' => 'A', 'name' => $rec_arr[0], 'address' => $rec_arr[1]);
}

if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "A records from DA: ".var_export($recs_a,true)."\n", FILE_APPEND);
}

if($recs_aaaa != false){
  // Build AAAA records array
  foreach ($recs_aaaa as $rec_key => $rec_val){
    // Split the record on =
    $rec_arr = explode("=",$rec_val);
    // DA only shows host, so build them to FQDN for comparison later
    if (strpos($rec_arr[0], $recs_domain) !== false) {
      // do nothing
    }else{
      $rec_arr[0] = $rec_arr[0].".".$recs_domain.".";
    }
    $recs_aaaa[$rec_key] = array($rec_arr[0],$rec_arr[1]);
    $da_clean_arr[] = array('type' => 'AAAA', 'name' => $rec_arr[0], 'address' => $rec_arr[1]);
  }

  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "AAAA records from DA: ".var_export($recs_aaaa,true)."\n", FILE_APPEND);
  }
}

if($recs_cname != false){
  // Build CNAME records array
  foreach ($recs_cname as $rec_key => $rec_val){
    // Split the record on =
    $rec_arr = explode("=",$rec_val);
    // DA only shows host, so build them to FQDN for comparison later
    if (strpos($rec_arr[0], $recs_domain) !== false) {
      // do nothing
    }else{
      $rec_arr[0] = $rec_arr[0].".".$recs_domain.".";
    }
    $recs_cname[$rec_key] = array($rec_arr[0],$rec_arr[1]);
    $da_clean_arr[] = array('type' => 'CNAME', 'name' => $rec_arr[0], 'cname' => $rec_arr[1]);
  }

  if($logging == true){
   file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "CNAME records from DA: ".var_export($recs_cname,true)."\n", FILE_APPEND);
  }
}


// Build MX records array
foreach ($recs_mx as $rec_key => $rec_val){
  // Split the record on =
  $rec_arr = explode("=",$rec_val);
  // We need to explode on space, to separate priority
  $rec2 = explode(" ",$rec_arr[1]);
  $recs_mx[$rec_key] = array($rec_arr[0],$rec2[0],$rec2[1]);
  $da_clean_arr[] = array('type' => 'MX', 'name' => $rec_arr[0], 'preference' => $rec2[0], 'exchange' => $rec2[1]);
}

if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "MX records from DA: ".var_export($recs_mx,true)."\n", FILE_APPEND);
}


// Build NS records array
foreach ($recs_ns as $rec_key => $rec_val){
  // Split the record on =
  $rec_arr = explode("=",$rec_val);
  $recs_ns[$rec_key] = array($rec_arr[1],$rec_arr[0]);
  $da_clean_arr[] = array('type' => 'NS', 'name' => $rec_arr[1], 'nsdname' => rtrim($rec_arr[0], "."));
}

if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "NS records from DA: ".var_export($recs_ns,true)."\n", FILE_APPEND);
}


// Build TXT records array
foreach ($recs_txt as $rec_key => $rec_val){
  // Split the record on =, txt can contain = so have to limit
  $rec_arr = explode("=",$rec_val, 2);
  $recs_txt[$rec_key] = array($rec_arr[1],$rec_arr[0]);
  $da_clean_arr[] = array('type' => 'TXT', 'name' => $rec_arr[0], 'txtdata' => $rec_arr[1]);
}

if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "TXT records from DA: ".var_export($recs_txt,true)."\n", FILE_APPEND);
}


// Build SRV records array
if($recs_srv != false){
  foreach ($recs_srv as $rec_key => $rec_val){
    // Split the record on =
    $rec_arr = explode("=",$rec_val);
    //SRV records need splitting again for priority weight port target
    $vals = explode(" ",$rec_arr[1]);
    $recs_srv[$rec_key] = array($rec_arr[0],$vals);
    $da_clean_arr[] = array('type' => 'SRV', 'name' => $rec_arr[0].".".$recs_domain.".", 'priority' => $vals[0], 'weight' => $vals[1], 'port' => $vals[2], 'target' => rtrim($vals[3],"."));
  }
}
if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "SRV records from DA: ".var_export($recs_srv,true)."\n", FILE_APPEND);
}


//file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "DA Records:\n ".var_export($da_clean_arr,true)."\n", FILE_APPEND);




#########################
# START records process #
#########################

// First we should see if this is a new zone on ns0
$zone_exists = check_zone_exists($recs_domain);

// If zone doesn't exist, then create the default cpanel zone on cluster
if($zone_exists == false){
  $command = "adddns?domain=".$recs_domain."&ip=".$recs_domip;
  send_to_ns($command);
}

// Get a clean zone array from cPanel
$cp_clean_arr = get_clean_cp_array($recs_domain);
//file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Clean cPanel record array:\n ".var_export($cp_clean_arr,true)."\n", FILE_APPEND);
$diff_arrays = compare_zones($cp_clean_arr, $da_clean_arr);
$cp_clean_arr = $diff_arrays[0];
$da_clean_arr = $diff_arrays[1];

// See what they look like now
if($logging == true){
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "DA Clean Records:\n ".var_export($da_clean_arr,true)."\n", FILE_APPEND);
  file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Clean cPanel records:\n ".var_export($cp_clean_arr,true)."\n", FILE_APPEND);
}

// Now delete the remaining cPanel records
foreach ($cp_clean_arr as $key => $cpval) {
  send_to_ns("removezonerecord?api.version=1&zone=".$recs_domain."&line=".$cpval['Line']);
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "deleting old cpanel record: ".var_export($cpval,true)."\n", FILE_APPEND);
  }
}

// Then add the DA ones
foreach ($da_clean_arr as $key => $da_rec) {
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "adding new DA record to zone:\n ".var_export($da_rec,true)."\n", FILE_APPEND);
  }
  add_record($recs_domain,$da_rec);
}


#############
# Functions #
#############
function send_to_ns($command){

  global $ns;
  global $logging;
  
  // Single curl
  /*
  foreach($ns as $key => $nameserver){
    
    $url = "https://".$nameserver['host'].":2087/json-api/".$command;
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array("Authorization: Basic " . base64_encode("root:".$nameserver['rootpw'])));
    curl_setopt($ch, CURLOPT_TIMEOUT, 100020);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
    $content = curl_exec($ch);
    curl_close($ch);
    
    if($logging == true){
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "send_to_ns running...\n", FILE_APPEND);
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "nameserver key: ".$key."\n", FILE_APPEND);
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Our cURL url: ".$url."\n", FILE_APPEND);
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "cPanel server said: ".$content."\n", FILE_APPEND);
    }
  }
  */
  
  ###### multicurl version
  
  // array of curl handles
  $multiCurl = array();
  // data to be returned
  $result = array();
  // multi handle
  $mh = curl_multi_init();
  //foreach ($ids as $i => $id) {
  foreach($ns as $i => $nameserver){
    $url = "https://".$nameserver['host'].":2087/json-api/".$command;
    $multiCurl[$i] = curl_init();
    curl_setopt($multiCurl[$i], CURLOPT_SSL_VERIFYHOST, 0);
    curl_setopt($multiCurl[$i], CURLOPT_SSL_VERIFYPEER, 0);
    curl_setopt($multiCurl[$i], CURLOPT_HEADER, 0);
    curl_setopt($multiCurl[$i], CURLOPT_URL, $url);
    curl_setopt($multiCurl[$i], CURLOPT_HTTPHEADER, array("Authorization: Basic " . base64_encode("root:".$nameserver['rootpw'])));
    curl_setopt($multiCurl[$i], CURLOPT_TIMEOUT, 100020);
    curl_setopt($multiCurl[$i], CURLOPT_RETURNTRANSFER, TRUE);
    curl_multi_add_handle($mh, $multiCurl[$i]);
  }
  $index=null;
  do {
    curl_multi_exec($mh,$index);
  } while($index > 0);
  // get content and remove handles
  foreach($multiCurl as $k => $ch) {
    $result[$k] = curl_multi_getcontent($ch);
    if($logging == true){
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "send_to_ns running...\n", FILE_APPEND);
      file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "cPanel server said: ".$result[$k]."\n", FILE_APPEND);
    }
    curl_multi_remove_handle($mh, $ch);
  }
  // close
  curl_multi_close($mh);
  
}


function check_zone_exists($domain){

  global $ns;
  global $logging;
    
  $url = "https://".$ns['ns1']['host'].":2087/json-api/dumpzone?api.version=1&domain=".$domain;
  
  $ch = curl_init();
  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
  curl_setopt($ch, CURLOPT_HEADER, 0);
  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array("Authorization: Basic " . base64_encode("root:".$ns['ns1']['rootpw'])));
  curl_setopt($ch, CURLOPT_TIMEOUT, 100020);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

  $content = curl_exec($ch);

  curl_close($ch);
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "check_dns_zone running...\n", FILE_APPEND);
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Our cURL url: ".$url."\n", FILE_APPEND);
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "cPanel server said: ".$content."\n\n", FILE_APPEND);
  }
  $result = json_decode($content,true);
  
  
  if($result['metadata']['result'] == "0" && $result['metadata']['reason'] == "Zone does not exist."){
    return false;
  }else if($result['metadata']['result'] == "1"){
    return true;
  }else{
    return false;
  }

}

function ns0_connect($command){

  global $ns;
  global $logging;
    
  $url = "https://".$ns['ns1']['host'].":2087/json-api/".$command;
  
  $ch = curl_init();
  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
  curl_setopt($ch, CURLOPT_HEADER, 0);
  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array("Authorization: Basic " . base64_encode("root:".$ns['ns1']['rootpw'])));
  curl_setopt($ch, CURLOPT_TIMEOUT, 100020);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

  $content = curl_exec($ch);

  curl_close($ch);
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "check_dns_zone running...\n", FILE_APPEND);
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Our cURL url: ".$url."\n", FILE_APPEND);
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "cPanel server said: ".$content."\n\n", FILE_APPEND);
  }
  $result = json_decode($content,true);
  
  return $result;
}

function compare_zones($cp_clean_arr, $da_clean_arr){
  // Compare and reduce the 2 arrays to eliminate matching records
  foreach ($da_clean_arr as $da_key => $da_rec){
    // Can we find a matching record?
    switch ($da_rec['type']) {
      case 'A':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "A" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['address'] == $da_rec['address']){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'AAAA':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "AAAA" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['address'] == ipv6_to_cpanelipv6($da_rec['address'])){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'CNAME':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          // cPanel won't show the dot on the end, add for comparison purposes
          if ($cp_rec['type'] == "CNAME" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['cname']."." == $da_rec['cname']){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'MX':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "MX" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['preference'] == $da_rec['preference'] && $cp_rec['exchange'] == $da_rec['exchange']){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'TXT':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "TXT" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['txtdata'] == $da_rec['txtdata']){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'NS':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "NS" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['nsdname'] == $da_rec['nsdname']){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      case 'SRV':
        foreach ($cp_clean_arr as $cp_key => $cp_rec){
          if ($cp_rec['type'] == "SRV" && $cp_rec['name'] == $da_rec['name'] && $cp_rec['priority'] == $da_rec['priority']  && $cp_rec['weight'] == $da_rec['weight']  && $cp_rec['port'] == $da_rec['port'] && $cp_rec['target'] == $da_rec['target'] ){
            // Unset record from both record arrays
            unset($da_clean_arr[$da_key]);
            unset($cp_clean_arr[$cp_key]);
            break;
          }
        }
      break;
      default:
          // nothing
    }
  }
  
  return array($cp_clean_arr, $da_clean_arr);
}

function get_clean_cp_array($recs_domain){
  global $logging;

  $cp_clean_arr = array();
  $cp_zone = ns0_connect("dumpzone?api.version=1&domain=".$recs_domain);
  $cp_zone = array_reverse($cp_zone['data']['zone'][0]['record']);
  
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "Records from cPanel:\n ".var_export($cp_zone,true)."\n", FILE_APPEND);
  }
  foreach ($cp_zone as $reccp => $cpval) {
    if($cpval['type'] == "A" || $cpval['type'] == "AAAA" || $cpval['type'] == "CNAME" || $cpval['type'] == "MX" || $cpval['type'] == "NS" || $cpval['type'] == "SRV"){
      $cp_clean_arr[] = $cpval;
    }
    if($cpval['type'] == "TXT"){
      $cpval['txtdata'] = "\"".$cpval['txtdata']."\"";
      $cp_clean_arr[] = $cpval;
    }
    
  }
  return $cp_clean_arr;
}

function add_record($recs_domain,$da_rec){
  global $logging;
  // add record to nameservers
  switch ($da_rec['type']) {
    case 'A':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=300&type=A&address=".$da_rec['address']);
    break;
    case 'AAAA':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=300&type=AAAA&address=".$da_rec['address']);
    break;
    case 'CNAME':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=300&type=CNAME&cname=".$da_rec['cname']);
    break;
    case 'MX':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=300&type=MX&preference=".$da_rec['preference']."&exchange=".$da_rec['exchange']);
    break;
    case 'TXT':
      // Try urlencoding the string then re-quoting it
      //file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "txtdata value before processing:\n ".$da_rec['txtdata']."\n", FILE_APPEND);
      $txtdata = ltrim($da_rec['txtdata'],"\"");
      $txtdata = rtrim($txtdata,"\"");
      //file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "txtdata value after detrim:\n ".$txtdata."\n", FILE_APPEND);
      $txtdata = rawurlencode($txtdata);
      //$txtdata = "\"".$txtdata."\"";
      //file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "txtdata value after urlencode:\n ".$txtdata."\n", FILE_APPEND);
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=300&type=TXT&txtdata=".$txtdata);
    break;
    case 'NS':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=3600&type=NS&nsdname=".$da_rec['nsdname']);
    break;
    case 'SRV':
      send_to_ns("addzonerecord?api.version=1&domain=".$recs_domain."&name=".$da_rec['name']."&class=IN&ttl=3600&type=SRV&priority=".$da_rec['priority']."&weight=".$da_rec['weight']."&port=".$da_rec['port']."&target=".$da_rec['target']);
    break;
  }

}

function ipv6_to_cpanelipv6($ipv6){
  global $logging;
  // for some reason, cPanel seems to use some weird shortening method for IPv6, which is basically just drop any leading zeros
  $ipv6_array = explode(":",$ipv6);
  foreach ($ipv6_array as $key => $octet){
    // strip leading zeros
    $ipv6_array[$key] = ltrim($octet,"0");
    // If it was all 0's then we need to make it just one, so if empty, reset to just 0
    if($ipv6_array[$key] == ""){
      $ipv6_array[$key] = "0";
    }else{
      // do nothing, should be ok.
    }
  }
  // and re-assemble
  $cpanelipv6 = implode(":",$ipv6_array);
  
  if($logging == true){
    file_put_contents("/usr/local/directadmin/scripts/custom/cpdnslog.txt", "shortened cPanel ipv6:\n".$cpanelipv6."\n", FILE_APPEND);
  }
  return $cpanelipv6;
}

