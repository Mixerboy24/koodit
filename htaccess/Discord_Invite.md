### Discord kutsulinkki verkkotunnukselle tai aliverkkotunnukselle

Saat oman Discord palvelimesi JSON tiedoston: Palvelinasetukset -> Pienoisohjelma. Laita ominaisuus päälle ja kopio JSON linkki. Muista myös määrittää kutsukanava

1. Luo juurihakemistoon invite.php tiedosto.
2. Liitä alla oleva koodi PHP tiedostoon. 
```php
<?php
// Avataan Discord API JSON-tiedosto
$json = file_get_contents('https://discord.com/api/guilds/<GUILD ID>/widget.json');

// Muutetaan se PHP:n taulukoksi
$data = json_decode($json, true);

// Haetaan invite.php mukaisen URL:in arvo
$inviteUrl = $data['instant_invite'];

// Ohjataan käyttäjä uudelleen
header("Location: $inviteUrl");
exit;
```

3. Lisää .htaccess tiedostoon:
```apache
RewriteEngine On  #Huomaa että tämä saattaa olla jo .htaccess tiedostossa.

RewriteCond %{REQUEST_URI} ^/invite$
RewriteRule ^(.*)$ invite.php [L]
```

Nyt esimerkki,fi/invite ohjaa käyttäjät Discord palvelimellesi. aina uudella kutsulla jota Discordin pienoisohjelma itse päivittää. 

Jos käytät aliverkkotunnusta (esimerkiksi discord.domain.tld), nimeä invite.php tiedoto index.php tiedostoksi. Sinun ei tarvitse muuttaa mitään .htaccess tiedostossa jos index.php on aliverkkotunnuksen juurihakemistossa.
