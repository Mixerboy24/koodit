#!/bin/bash
CT_ID=<Container ID>
API_KEY="API_KEY"
OCTOPRINT_URL="http://localhost:5000/api/connection"
LOG_FILE="/var/log/octoprint_monitor.log"

# Hae tila ja tarkista virhetilat
response=$(curl -s -m 10 -H "X-Api-Key: $API_KEY" "$OCTOPRINT_URL")
exit_code=$?

# Tarkista curl-virheet (esim. timeout, ei yhteyttä)
if [[ $exit_code -ne 0 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Curl-virhe: $exit_code" >> "$LOG_FILE"
    exit 1
fi

# Parsi JSON-vastaus
state=$(echo "$response" | grep -oP '"state":\s*"\K[^"]+')

# Tarkista vain tietynlaiset virhetilat
if [[ "$state" == "Offline" || "$state" == "Offline after error" || "$state" == "Closed" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Virhetila: $state. Käynnistetään CT $CT_ID uudelleen." >> "$LOG_FILE"
    /usr/sbin/pct reboot "$CT_ID"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Tila OK: $state" >> "$LOG_FILE"
fi
