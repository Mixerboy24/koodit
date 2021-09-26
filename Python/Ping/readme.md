### Allsky status

Python scripti pingaa Allsky kameran järjestelmää (esim Raspia) joka kirjoittaa tuloksen tiedostoon.     
Kyseessähän on yksinkertainen Py3 scripti.    

Vaatii toimiakseen yhden ylimääräisen koneen tai laitteen joka kykenee suorittamaan Python3 scriptiä.    

Miten LocalghostFI hyödyntää tätä?
V: LGFI hyödyntää scriptiä seuraavasti:    

1. Sisäverkossa on Raspi 4 joka lähettää kuvan yms tiedoston allsky.mb24.fi palvelimelle. Samainen raspi hoitaa 2min välein pingauksen Allskyhyn. 5min välein raspi lähettää kuvan + status.txt:n allsky.mb24.fi palvelimelle.
2. Uptimerobots lukee Keyword ominaisuudella allsky.mb24.fi/status.txt tiedostoa. Jos siellä lukee "DOWN", uptimerobot merkkaa että palvelu on alhaalla.

Tällä tavalla saadaan tietoon jos Allskyn kone on pois päältä syystä X (Esim sähkökatkos).   
