# Live Preflight Policy

Generated from `GemStonePharoContract` live preflight policy.

## Purpose

The live preflight classifies local GemStone connectivity before the live regression lane runs.
Both the standalone preflight script and the in-process full verification lane delegate to `GemStonePharoVerificationRunner`.

## Required Environment

- `GS_USER`
  GemStone login user used by both the Topaz and GCI probes.
- `GS_PASS`
  GemStone login password used by both the Topaz and GCI probes.
- `GS_STONE`
  Optional stone name override. Defaults to `gs64stone`.
- `GS_SERVICE`
  Optional service name override. Defaults to `gemnetobject`.
- `GS_NETLDI_HOST`
  Optional explicit host for netldi routing.
- `GS_NETLDI_NAME_OR_PORT`
  Optional explicit netldi name or port, for example `gs64ldi` or `50377`.
- `GEMSTONE`
  Optional explicit GemStone client home used by the GCI probe.

## Probe Steps

- `stone-status`
  Inspect the local stone and netldi state with `gslist -lcv` when available.
- `topaz-login`
  Attempt a Topaz login using the configured stone, service, host, and netldi route.
- `gci-login`
  Attempt a direct GCI login from Pharo using the same route and client library.
- `summary`
  Emit `LIVE_PREFLIGHT_SUMMARY` and optional JSON with the final classification.

## Summary Fields

- `result`
- `code`
- `stone`
- `service`
- `host`
- `net`
- `stone_status`
- `netldi_status`
- `topaz`
- `gci`

## Result Codes

- `LIVE_PREFLIGHT_OK`
  Both Topaz and GCI probes succeeded.
- `LIVE_PREFLIGHT_SKIPPED`
  The live lane was skipped because login credentials were not supplied.
- `LIVE_PREFLIGHT_AUTH_FAILED`
  Topaz login failed due to invalid credentials.
- `LIVE_PREFLIGHT_ROUTE_FAILED`
  Topaz could not route through the configured host/netldi combination.
- `LIVE_PREFLIGHT_STONE_NOT_FOUND`
  The target stone was not visible through the configured route.
- `LIVE_PREFLIGHT_TOPAZ_LOGIN_FAILED`
  Topaz login failed for a non-routing, non-auth reason.
- `LIVE_PREFLIGHT_GCI_AUTH_FAILED`
  The Pharo GCI login failed due to invalid credentials.
- `LIVE_PREFLIGHT_GCI_ROUTE_FAILED`
  The Pharo GCI login could not route through the configured host/netldi combination.
- `LIVE_PREFLIGHT_GCI_STONE_NOT_FOUND`
  The Pharo GCI login could not find the target stone.
- `LIVE_PREFLIGHT_GCI_LOGIN_FAILED`
  The Pharo GCI login failed for a non-routing, non-auth reason.
