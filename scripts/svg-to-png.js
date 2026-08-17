// Convertit tous les SVG dans assets/images/ en PNG 24x24 (transparent)
// Usage: npm install sharp glob && node scripts/svg-to-png.js

const sharp = require('sharp');
const glob = require('glob');
const path = require('path');
const fs = require('fs');

const SRC_DIR = path.resolve(__dirname, '..', 'assets', 'images');
const OUT_DIR = SRC_DIR; // écrase ou ajoute _24.png

glob(path.join(SRC_DIR, '*.svg'), {}, (err, files) => {
  if (err) throw err;
  if (!files.length) return console.log('Aucun SVG trouvé dans', SRC_DIR);

  files.forEach(file => {
    const name = path.basename(file, '.svg');
    const out = path.join(OUT_DIR, `${name}_24.png`);
    sharp(file)
      .resize(24, 24, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png({ compressionLevel: 9 })
      .toFile(out)
      .then(() => console.log('Généré', out))
      .catch(e => console.error('Erreur pour', file, e));
  });
});