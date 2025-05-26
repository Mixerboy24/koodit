# OctoPrint Container Monitor

Shell-skripti, joka valvoo OctoPrintin yhteyden tilaa ja käynnistää Proxmox-kontin (CT) uudelleen virhetilanteissa. Ajetaan cronin kautta.

## Ominaisuudet
- Tarkistaa OctoPrintin API:n kautta tulostimen tilan.
- Uudelleenkäynnistää Proxmox-kontin (CT), jos tila on:
  - `Offline`
  - `Offline after error`
  - `Closed`
  - `Opening serial connection`
- Lokittaa kaikki toimenpiteet `/var/log/octoprint_monitor.log`.

## Vaatimukset
- **OctoPrint** asennettuna Proxmox LXC-kontissa (CT).   
 - Jos ei ole, Asenna Octoprint Proxmoxiin: https://community-scripts.github.io/ProxmoxVE/scripts?id=octoprint
- **curl** asennettuna (`apt install curl`).
- Oikeudet ajaa `pct reboot`-komentoja (suorita rootina).
- OctoPrintin **API-avain** (luo OctoPrintin asetuksista: *Settings > API*).

## Asennus

### 1. Lataa skripti
```bash
wget https://raw.githubusercontent.com/Mixerboy24/koodit/refs/heads/main/Proxmox/Automation/Octoprint/octoprint_monitor.sh -O /usr/local/bin/octoprint_monitor.sh
chmod +x /usr/local/bin/octoprint_monitor.sh
```

### 2. Muokkaa muuttujat
```bash
nano /usr/local/bin/octoprint_monitor.sh
```
Muokkaa:

```bash
CT_ID=100                 # Korvaa OctoPrint-kontin ID:llä
API_KEY="API_KEY"         # Korvaa OctoPrintin API-avaimella
OCTOPRINT_URL="http://<IP / DOMAIN>:5000/api/connection"  # Korvaa oikea osoite. Esim: 192.168.1.41
```
### 3. Lisää cron-tehtävä
```bash
crontab -e
```
### Lisää rivi (ajetaan 5 minuutin välein):
```bash
*/5 * * * * /usr/local/bin/octoprint_monitor.sh
```
### Lokitus

Skripti kirjoittaa lokitiedostoon /var/log/octoprint_monitor.log:

```bash
tail -f /var/log/octoprint_monitor.log
```

Esimerkkiloki:
```
2025-04-28 22:41:51 - Tila OK: Operational
2025-04-28 22:45:01 - Virhetila: Offline. Käynnistetään CT 1001 uudelleen.
2025-04-28 22:50:01 - Tila OK: Printing
2025-04-28 22:55:01 - Tila OK: Printing
2025-04-28 23:00:01 - Tila OK: Printing
```
### Testaus
Simuloi virhe irrottamalla tulostimen USB-kaapeli.

Odota 5 minuuttia (tai aja skripti manuaalisesti):

```bash
/usr/local/bin/octoprint_monitor.sh
```
### Vianmääritys
- API ei vastaa: Tarkista OctoPrintin URL ja API-avain.
- Ei uudelleenkäynnistystä:
  - Varmista, että ```pct reboot``` toimii manuaalisesti.
  - Tarkista cronin lokit: ```grep CRON /var/log/syslog```.
