#!/usr/bin/env python3

# Octoprint tulostimen tarkistin
# Dev: Atte "Mixerboy24" Oksanen / LocalghostFI
# (c) LocalghostFI

# Ajetaan Crotabilla 5min välein root oikeuksilla. 

import requests
import json
import subprocess
from datetime import datetime

CT_ID = 100 # Octoprint CT:n ID Proxmoxissa.
OCTOPRINT_URL = "http://IP_URI:5000/api/connection"  # OctoPrintin osoite ja portti. Oletuksena 5000
OCTOPRINT_API_KEY = "API_KEY"  # OctoPrintin API-avain

LOG_FILE = "/var/log/ct_octoprint_monitor.log"

def log_message(message):
    with open(LOG_FILE, 'a') as log:
        log.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")
    subprocess.run(['logger', message])

def check_octoprint_status():
    headers = {
        "Content-Type": "application/json",
        "X-Api-Key": OCTOPRINT_API_KEY
    }

    try:
        response = requests.get(OCTOPRINT_URL, headers=headers)
        if response.status_code == 200:
            data = response.json()
            current_state = data['current']['state']
            return current_state
        else:
            log_message(f"Ei voitu hakea tulostimen tilaa. HTTP-virhekoodi: {response.status_code}")
            return None
    except Exception as e:
        log_message(f"Virhe tulostimen tilan tarkistuksessa: {str(e)}")
        return None

def main():
    current_state = check_octoprint_status()

    if current_state is None:
        return
    
    if current_state in ["Offline", "Offline after error", "Closed"]:
        log_message(f"Tulostin ei ole operatiivinen (tila: {current_state}), käynnistetään uudelleen CT {CT_ID}...")
        subprocess.run(['pct', 'reboot', str(CT_ID)])
    else:
        log_message(f"Tulostin on operatiivinen (tila: {current_state}), ei toimenpiteitä tarvita.")

if __name__ == "__main__":
    main()
