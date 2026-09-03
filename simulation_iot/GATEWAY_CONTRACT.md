# Contrat passerelle IoT GEODEX

La passerelle (ESP32 ou Raspberry Pi) pilote le lecteur RFID, le module HX711
et l'imprimante thermique. Flutter ne communique qu'avec le backend GEODEX.

## Etat materiel

La passerelle envoie periodiquement ses disponibilites :

```http
POST /api/pesees/bornes/etat
Content-Type: application/json

{
  "rfid": true,
  "balance": true,
  "imprimante": true,
  "reseau": true,
  "modeDemo": false
}
```

Le terminal lit `GET /api/pesees/bornes/etat` toutes les cinq secondes.

## Poids HX711

La passerelle publie le poids mesure et sa stabilite :

```http
POST /api/pesees/bornes/poids
Content-Type: application/json

{ "poidsG": 24.65, "stabilise": true }
```

Une balance indisponible est declaree avec `balance: false`; le backend
retourne alors une erreur exploitable par l'ecran de la borne.

## Impression thermique

Apres generation du passeport signe, le terminal appelle :

```http
POST /api/pesees/passports/print
Content-Type: application/json

{ "passeportId": "uuid-du-passeport" }
```

La passerelle doit recevoir cette commande via son connecteur backend et
imprimer le ticket avec le QR et les informations du passeport. La signature
et les donnees de passeport restent generees par le serveur.
