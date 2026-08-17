# Usage des assets SVG/PNG

Fichiers dans ce dossier:

- `logo_dark.svg`, `logo_light.svg`
- `logo.svg` (générique)
- `icon_pin(_light/_dark).svg`
- `icon_layer(_light/_dark).svg`
- `icon_user(_light/_dark).svg`
- `icon_alert(_light/_dark).svg`
- `*_24.png` (générés par `scripts/svg-to-png.js`)

## Recommandations d'utilisation

- Préférez les SVG (`SvgPicture.asset`) pour une mise à l'échelle nette.
- Utilisez les variantes `*_dark.svg` pour le thème sombre et `*_light.svg` pour le thème clair.
- Si vous avez besoin de PNG (compatibilité), générez-les via `node scripts/svg-to-png.js`.

## Exemples Flutter

- Charger un SVG:

  `SvgPicture.asset('assets/images/icon_pin_dark.svg', width: 18, height: 18)`

- Charger un PNG fallback:

  `Image.asset('assets/Gemini_Generated_Image_.png', width: 40, height: 40)`

## Script de génération PNG

- `scripts/svg-to-png.js`
- Installer : `npm install sharp glob`
- Exécuter : `node scripts/svg-to-png.js`

## Couleurs

- Les couleurs sont intégrées dans les SVGs. Pour recolorer dynamiquement, utilisez des SVGs avec `currentColor` et enveloppez dans `DefaultTextStyle` ou manipulez le XML avant rendu.
