#!/bin/bash
# /home/pi/allsky-watchdog.sh
LOG=/var/log/allsky-watchdog.log
STAMPS=/var/log/allsky-watchdog-reboots.log
ZWO_VID=03c3          # ZWOptical vendor id
MIN_UPTIME=600
MAX_REBOOTS=3
WINDOW=3600

log(){ echo "$(date '+%F %T') $*" >> "$LOG"; }

# 1) Kaikki ok? -> ei tehdä mitään
systemctl is-active --quiet allsky.service && exit 0

# 2) Juuri boottailtu -> odotetaan
up=$(awk '{print int($1)}' /proc/uptime)
[ "$up" -lt "$MIN_UPTIME" ] && { log "kuollut mutta uptime ${up}s < ${MIN_UPTIME}s, odotetaan"; exit 0; }

# 3) USB-reset: unbind+bind ZWO-kameralle (tämä korjaa sen descriptor-jumin)
resetoitu=0
for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/idVendor" ] || continue
    if [ "$(cat "$dev/idVendor")" = "$ZWO_VID" ]; then
        port=$(basename "$dev")
        log "USB-reset ZWO-kameralle portissa $port"
        echo "$port" > /sys/bus/usb/drivers/usb/unbind 2>>"$LOG"
        sleep 2
        echo "$port" > /sys/bus/usb/drivers/usb/bind 2>>"$LOG"
        resetoitu=1
    fi
done
[ "$resetoitu" -eq 0 ] && log "ZWO-kameraa ei näy USB:llä lainkaan (ei enumeroidu) -> USB-reset ei auta, mennään reboottiin"

# 4) Restart jotta palvelu tarttuu kameraan uudelleen
if [ "$resetoitu" -eq 1 ]; then
    log "restart allsky.service USB-resetin jälkeen"
    systemctl restart allsky.service
    sleep 30
    systemctl is-active --quiet allsky.service && { log "USB-reset + restart auttoi ✅ (ei tarvittu reboottia)"; exit 0; }
fi

# 5) Loop-suoja
now=$(date +%s)
touch "$STAMPS"
recent=$(awk -v n="$now" -v w="$WINDOW" '$1 > n-w' "$STAMPS" | wc -l)
if [ "$recent" -ge "$MAX_REBOOTS" ]; then
    log "⛔ $recent reboottia viime tunnissa -> EI enää rebootata (luultavasti rautavika: tarkista USB-kaapeli/virransyöttö)"
    exit 0
fi

# 6) Reboot viimeisenä keinona
echo "$now" >> "$STAMPS"
log "USB-reset+restart ei auttanut, rebootataan 🔁 (reboot #$((recent+1)) tunnin sisällä)"
/sbin/reboot
