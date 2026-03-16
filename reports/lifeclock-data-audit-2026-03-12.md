# LifeClock Data Audit

Generated: 2026-03-12
App Store Connect app id: `6760122665`
Bundle id: `com.GA.LifeClock`
Current ASC app name: `Life Time Tracker: LifeChron`

## Summary

- No live usage signals are currently available from App Store Connect.
- The iOS and macOS versions are both still in `PREPARE_FOR_SUBMISSION`.
- No builds are currently uploaded to App Store Connect.
- No App Store reviews or review summaries are currently available.
- App Store analytics requests are blocked by the current Apple API key permissions.
- RevenueCat project and product configuration exist, but RevenueCat metrics are blocked by the current key permissions.

## App Store Connect

### App status

- App name: `Life Time Tracker: LifeChron`
- SKU: `LifeChron`
- Primary locale: `en-US`
- Bundle id: `com.GA.LifeClock`

### Version status

- iOS `1.0`: `PREPARE_FOR_SUBMISSION`
- macOS `1.0`: `PREPARE_FOR_SUBMISSION`
- Both versions were created on `2026-03-05T06:00:33-08:00`

### Builds

- Uploaded builds in ASC: `0`

### Reviews and performance

- Customer reviews found: `0`
- Review summarizations found: `0`
- Performance metric payload returned no product data and no insights

### In-app purchase

- Product: `LifeClock Lifetime`
- Product id: `com.GA.LifeClock.lifetime`
- Type: `NON_CONSUMABLE`
- State: `READY_TO_SUBMIT`
- Base territory: `DEU`
- Current price: `7.99 EUR`
- Estimated proceeds: `5.71 EUR`

### Data access blockers

- `asc analytics requests --app 6760122665` returned:
  `The API key in use does not allow this request`
- `asc insights weekly --source analytics` returned all analytics metrics as unavailable because the analytics source is not permitted for the current API key.
- Sales and finance report export could not be executed because no App Store vendor number is configured locally.

## RevenueCat

### Configuration status

- Project found: `LifeClock`
- Project id: `proj78873872`
- App found for bundle id `com.GA.LifeClock`
- Product found: `com.GA.LifeClock.lifetime`
- Current offering found: `default`
- Public SDK key is configured

### Product and entitlement structure

- Product:
  - `com.GA.LifeClock.lifetime`
- Current offering:
  - lookup key `default`
- Current package:
  - lookup key `$rc_lifetime`
- Active entitlement used by the app:
  - lookup key `premium`
- Additional legacy entitlement still exists:
  - lookup key `LifeClock Pro`
  - attached product identifier appears as `lifetime`

### Data access blockers

- RevenueCat overview metrics request returned:
  `The API key needs at least the charts_metrics:overview:read permission defined`

## Interpretation

- This is not a "bad performance" situation. It is a "pre-distribution / limited-permission" situation.
- The absence of App Store reviews, performance metrics, builds, and analytics strongly suggests the app has not yet reached a state where Apple can generate meaningful usage data.
- Monetization setup is mostly in place on both Apple and RevenueCat.
- The duplicated RevenueCat entitlement setup should be cleaned up to avoid future confusion during entitlement checks, dashboard analysis, or support work.

## Recommended next steps

1. Upload at least one iOS build to App Store Connect and connect it to the iOS 1.0 version.
2. Add or confirm the App Store vendor number locally so sales and finance exports can run.
3. Use an Apple API key that has permission for analytics report requests.
4. Use a RevenueCat API key with `charts_metrics:overview:read` if monetization analytics should be pulled automatically.
5. Remove or archive the legacy RevenueCat entitlement `LifeClock Pro` if it is no longer used.
6. After the first TestFlight or live distribution period, rerun the same audit to collect actual acquisition, monetization, and feedback data.
