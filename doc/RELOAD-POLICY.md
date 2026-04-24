# Reload Policy

Generated from `GemStonePharoContract` reload policy and lane contracts.

## Purpose

The clean reload lane loads the helper package, hands bootstrap unload/cache-warm/load work to `GemStonePharoReloadBootstrapper`, runs architecture/ownership/no-compatibility/artifact checks through `GemStonePharoReloadRunner` and `GemStonePharoReloadGuards`, and can invoke `GemStonePharoVerificationRunner` in the same Smalltalk process when a verification lane is requested. Top-level `make verify` sequencing is owned by `GemStonePharoVerifyRunner`.

## Environment

- `GBS_LOAD_GROUP`
  Metacello load group to reload before post-load checks run. Defaults to `default`.
- `GBS_RELOAD_CHECK_MODE`
  Reload proof mode. Defaults to `default` and supports `core-only`.
- `GBS_VERIFY_LANE`
  Optional verification lane to run in the same Smalltalk process after the reload proof. Supports `core-only`, `original`, `original-tests`, and `full`.
- `GBS_GENERATE_CONTRACT_ARTIFACTS`
  When `1`, regenerate the contract-driven documentation after reload.
- `GBS_VERIFY_CONTRACT_ARTIFACTS`
  When `1`, verify that the contract-driven documentation is already fresh.

## Reload Modes

- `default`
  Run the steady-state reload proof, including no-compatibility checks after the requested load group is loaded.
- `core-only`
  Run the core-only package/class/selector proof after loading `Core-Tests`, plus the no-compatibility image proof.

## Verification Lanes

- `core-only`
  Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.
- `bootstrap-smoke`
  Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.
- `original`
  Verify that the original/base production layer reloads cleanly without the generic Core or optional MagLev overlays.
- `original-drift`
  Verify that the original/base production layer stays clean relative to `56b6db3...`, allowing only the explicit accepted test-layer exceptions.
- `original-tests`
  Verify the original/base production and original/base test layer without the generic Core or optional MagLev overlays. This lane proves the base unit layer only.
- `full`
  Verify the steady-state developer load plus the live GemStone lane.
- `artifact-freshness`
  Verify that the generated contract artifacts and marker-managed doc sections are already up to date.
- `verify`
  Run core-only, bootstrap-smoke, original, original-drift, original-tests, full, artifact-freshness, then the summary-renderer smoke check.
