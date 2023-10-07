# Kutsulinkki Discord-palvelimellesi verkkotunnuksella tai aliverkkotunnuksella

Luo kutsulinkki Discord-palvelimellesi käyttämällä JSON-tiedostoa: Palvelinasetukset -> Pienoisohjelma. Ota ominaisuus käyttöön ja kopioi JSON-linkki. Varmista myös, että määrität kutsukanavan.

1. Luo `invite.php`-tiedosto juurihakemistoon.

2. Liitä seuraava PHP-koodi `invite.php`-tiedostoon:

   ```php
   <?php
   // Avaa Discord API:n JSON-tiedosto
   $json = file_get_contents('https://discord.com/api/guilds/<GUILD ID>/widget.json');

   // Muunna se PHP-taulukoksi
   $data = json_decode($json, true);

   // Hae kutsun URL-osoite invite.php:lle
   $inviteUrl = $data['instant_invite'];

   // Ohjaa käyttäjä
   header("Location: $inviteUrl");
   exit;
   ```
   Korvaa `<GUILD ID>` todellisella Discord-palvelimesi ID:llä.

3. Lisää seuraava koodi `.htaccess`-tiedostoon:
   ```apache
   RewriteEngine On  # Huomaa, että tämä saattaa jo olla .htaccess-tiedostossasi.

   RewriteCond %{REQUEST_URI} ^/discord$
   RewriteRule ^(.*)$ invite.php [L]
   ```

Nyt, kun käyttäjät vierailevat osoitteessa `esimerkki.fi/discord`, he ohjautuvat Discord-palvelimellesi uudella kutsulinkillä, joka päivittyy Discordin pienoisohjelman avulla.       
   
HUOM! Jos käytät aliverkkotunnusta (esim., `discord.domain.tld`), nimeä `invite.php`-tiedosto `index.php`:ksi.    
Sinun ei tarvitse muokata mitään `.htaccess`-tiedostossa, jos index.php on aliverkkotunnuksen juurihakemistossa.

