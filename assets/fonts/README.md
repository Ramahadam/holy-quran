# Font Assets

## UthmanicHafs_V22.ttf

Used for Classic Mode Quran text rendering.

The bundled font identifies itself as `KFGQPC HAFS Uthmanic Script Regular`, version 2.2, by King Fahd Glorious Quran Printing Complex.

- Source of truth: https://fonts.qurancomplex.gov.sa/en/hafs-reading/
- Official KFGQPC archive URL: https://fonts.qurancomplex.gov.sa/wp-content/uploads/fonts/UthmanicHafs_v22.zip
- Official archive SHA-256 listed by the Arch Linux AUR `ttf-qurancomplex-fonts` package: `b5cf0666441aabd5ff2be4993934e6f2a57d00b6b89afcdf708cd70288671b23`
- Reachable pinned font source: https://static-cdn.tarteel.ai/qul/fonts/UthmanicHafs_V22.ttf
- Checked-in font SHA-256: `aa68bffce289b4c0ebac68e90502eb69e42356abcd1603cb2b8e99c2c723f145`

The official KFGQPC hosts were not reachable from the local environment or GitHub Actions during this change, so CI verifies the checked-in file against the pinned Quranic Universal Library/Tarteel CDN copy and the SHA-256 above:

```bash
scripts/verify_qpc_hafs_font.sh
```

The font metadata identifies King Fahd Glorious Quran Printing Complex as the author/manufacturer and grants free use/copy/distribution subject to the included EULA restrictions. Do not modify the font file.
