# Hybrid Monetization Setup (Option B)

This automation implements the robust hybrid flow:
1. App Store Connect API: create/check iOS lifetime IAP
2. RevenueCat API v2: app/product/entitlement/offering/package setup
3. Local Xcode patch: inject RevenueCat keys into `project.pbxproj`

## Files
- `scripts/monetization/asc_iap_upsert.sh`
- `scripts/monetization/revenuecat_sync.sh`
- `scripts/monetization/xcode_set_revenuecat_key.sh`
- `scripts/monetization/run_hybrid_setup.sh`
- `scripts/monetization/.env.hybrid.example`

## Quick Start
```bash
cp scripts/monetization/.env.hybrid.example .env.hybrid
# fill all required values in .env.hybrid

scripts/monetization/run_hybrid_setup.sh --env .env.hybrid
```

## Run Individual Steps
```bash
scripts/monetization/asc_iap_upsert.sh --env .env.hybrid
scripts/monetization/revenuecat_sync.sh --env .env.hybrid
scripts/monetization/xcode_set_revenuecat_key.sh --env .env.hybrid
scripts/monetization/asc_iap_upload_review_screenshot.sh --env .env.hybrid --file /absolute/path/review.png
scripts/monetization/asc_upload_app_screenshots.sh --env .env.hybrid --display-type APP_IPHONE_65 --file /absolute/path/shot1.png
```

## What this setup does (idempotent)
- Creates lifetime IAP in ASC only if missing.
- Optionally sets IAP availability for all territories.
- Optionally sets IAP base price via price schedule.
- Creates RevenueCat app/product/entitlement/offering/package only if missing.
- Attaches product to entitlement/package only if missing.
- Sets offering `default` as current (if configured).
- Fetches RevenueCat public SDK key and patches these Xcode build settings:
  - `INFOPLIST_KEY_REVENUECAT_PUBLIC_SDK_KEY`
  - `INFOPLIST_KEY_REVENUECAT_ENTITLEMENT_ID`
  - `INFOPLIST_KEY_REVENUECAT_OFFERING_ID`
  - `INFOPLIST_KEY_REVENUECAT_LIFETIME_PRODUCT_ID`

## Prerequisites you must provide
- App Store Connect API key (`.p8`, key id, issuer id).
- ASC app numeric ID.
- RevenueCat API v2 secret key with project configuration permissions.
- RevenueCat project reference (`RC_PROJECT_ID` or exact `RC_PROJECT_NAME`).

## Still manual after automation
- App Store Connect final review details.
- App metadata/screenshots/submission in App Store Connect.
- End-to-end sandbox purchase + restore verification on device/simulator.
- TestFlight validation before release.
