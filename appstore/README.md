# App Store Connect Workflow

This repository now keeps the editable App Store listing state in versioned files:

- `appstore/metadata/app-info/en-US.json`
- `appstore/metadata/version/en-US.json`
- `appstore/review/notes.txt`

Run the release scripts in this order:

```bash
scripts/release/asc_sync_metadata.sh --env .env.release
scripts/release/asc_configure_listing.sh --env .env.release
scripts/release/asc_capture_screenshots.sh --env .env.release
scripts/release/asc_upload_screenshots.sh --env .env.release
scripts/release/asc_publish_appstore.sh --env .env.release --build
scripts/release/asc_validate_submission.sh --env .env.release
```

For a one-command preparation run:

```bash
scripts/release/asc_prepare_submission.sh --env .env.release
```

The scripts derive the current iOS version from the Xcode project and sync against the existing App Store Connect app/version instead of creating parallel state.
