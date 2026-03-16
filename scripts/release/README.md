# App Store Connect CLI Setup

Diese Release-Skripte sind auf die iOS-App `LifeClock` ausgelegt:
- Projekt: `LifeClock.xcodeproj`
- Scheme: `LifeClock`
- Bundle ID: `com.GA.LifeClock`
- Team ID: `LPPZFWPAN7`

## 1. asc ist bereits installiert
```bash
asc --version
```

## 2. Apple API Key anlegen
In App Store Connect:
`Users and Access` -> `Integrations` -> `App Store Connect API`

Du brauchst:
- `Issuer ID`
- `Key ID`
- die einmal herunterladbare `AuthKey_XXXXXXX.p8`

Empfohlene Rollen:
- mindestens `App Manager`
- oder `Admin`, wenn du alles darüber steuern willst

## 3. Lokale Release-Konfiguration anlegen
```bash
cp scripts/release/.env.release.example .env.release
```

Dann `.env.release` ausfüllen:
- `APPLE_ISSUER_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY_PATH`
- `APPLE_APP_ID`
- optional `ASC_TESTFLIGHT_GROUPS`
- optional für manuellen Store-Export ohne eingeloggte Xcode-Session:
  - `APPSTORE_EXPORT_SIGNING_STYLE=manual`
  - `APPSTORE_APP_PROFILE_NAME`
  - `APPSTORE_WIDGET_PROFILE_NAME`
  - `APPSTORE_SIGNING_CERTIFICATE=Apple Distribution`

Die Datei `.env.release` ist bereits in `.gitignore`.

## 4. asc mit Keychain-Profil einrichten
```bash
scripts/release/asc_auth_login.sh --env .env.release
```

Danach kannst du den App Store Connect App ID auch per Bundle ID nachschlagen:
```bash
asc --profile LifeClock apps list --bundle-id com.GA.LifeClock --output table
```

## 5. IPA bauen
```bash
scripts/release/asc_build_ipa.sh --env .env.release
```

Artefakte landen unter:
- `.asc/artifacts/LifeClock.xcarchive`
- `.asc/artifacts/LifeClock.ipa`

## 6. Nach TestFlight veröffentlichen
```bash
scripts/release/asc_publish_testflight.sh --env .env.release --build
```

Voraussetzung:
- `ASC_TESTFLIGHT_GROUPS` ist gesetzt, z. B. `Internal Testers`

## 7. In den App Store hochladen
Ohne direkte Submission:
```bash
scripts/release/asc_publish_appstore.sh --env .env.release --build
```

Mit direkter Review-Submission:
```bash
scripts/release/asc_publish_appstore.sh --env .env.release --build --submit
```

## 8. Listing, Screenshots und Review-Details synchronisieren
Einmalig oder vor jeder neuen Store-Version:
```bash
scripts/release/asc_sync_metadata.sh --env .env.release
scripts/release/asc_configure_listing.sh --env .env.release
scripts/release/asc_capture_screenshots.sh --env .env.release
scripts/release/asc_render_marketing_screenshots.sh --env .env.release
scripts/release/asc_upload_screenshots.sh --env .env.release
scripts/release/asc_validate_submission.sh --env .env.release
```

Komplett in einem Rutsch:
```bash
scripts/release/asc_prepare_submission.sh --env .env.release
```

## Hinweise
- Die Skripte nutzen `asc` und speichern Auth standardmäßig im macOS-Keychain.
- `ALLOW_PROVISIONING_UPDATES=false` ist absichtlich konservativ gesetzt. Falls Xcode wegen Signierung/Profilem meckert, setze es lokal auf `true`.
- Falls `xcodebuild -exportArchive` keine Profile findet, nutze den manuellen Export-Modus mit expliziten `APPSTORE_*_PROFILE_NAME`-Werten.
- App-Privacy-Nutrition-Labels sind weiterhin separat in App Store Connect zu pflegen; die ASC-CLI deckt diesen Bereich derzeit nicht ab.
