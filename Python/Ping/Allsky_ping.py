#!/usr/bin/python3

import subprocess
import platform
 
f = open('status.txt', 'r+')
f.truncate(0)
f.close()

f = open('status.txt', 'a')


def ping_ip(Allsky_ip):
        try:
            output = subprocess.check_output("ping -{} 1 {}".format('n' if platform.system().lower(
            ) == "windows" else 'c', Allsky_ip ), shell=True, universal_newlines=True)
            if 'unreachable' in output:
                return False
            else:
                return True
        except Exception:
                return False
 
if __name__ == '__main__':
    Allsky_ip = ['ALLSKYIP']
    for each in Allsky_ip:
        if ping_ip(each):
            f.write(f"UP"+'\n')
        else:
            f.write(f"Down"+'\n')
    f.close()

# Allsky kameran Raspberryn päällä olon tarkastus. 
# Scripti kirjoittaa status.txt tiedostoon UP jos Allksy on päällä ja DOWN jos se ei oo päällä. 
# Status.txt lähetetään FTP:llä palvelimelle josta esim Uptimerobots voi sen lukea. 
# (C)2021 LocalghostFI / https://localghost.fi / contact@localghost.fi
