#!/bin/bash

API_KEY="CF API-avain"
EMAIL="CF kirjatumisen maili"
ZONE_ID="XXX"
RECORD_NAME="sub.domain.fi"    

CURRENT_IP=""
RECORD_ID=""    

while true; do

  NEW_IP=$(curl -s https://api.ipify.org)
  
  if [ "$CURRENT_IP" != "$NEW_IP" ]; then
    echo "IP-osoite on muuttunut: $NEW_IP"
    
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
                -H "X-Auth-Email: $EMAIL" \
                -H "X-Auth-Key: $API_KEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$NEW_IP\",\"ttl\":1,\"proxied\":false}"
    
    echo "Tietue päivitetty."
    
    CURRENT_IP="$NEW_IP"
  else
    echo "IP-osoite ei ole muuttunut."
  fi

  sleep 600  # Odota 10 minuuttia ennen seuraavaa tarkastusta
done

