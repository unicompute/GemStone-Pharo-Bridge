---
name: verify
description: Build/launch/drive recipe for verifying GemStone-Pharo-Bridge changes end-to-end against a live stone
---

# Verifying GemStone-Pharo-Bridge

## Prereqs
- Stone + netldi up: `$GEMSTONE/bin/gslist -l` must show `gs64stone` and `gs64ldi`.
- **Verify the DataCurator password first** (it depends on which extent the stone booted):
  `printf 'set gemstone gs64stone user DataCurator pass swordfish\nset gemnetid !#netldi:gs64ldi!gemnetobject\nlogin\nexit\n' | "$GEMSTONE/bin/topaz" -q`
  — try `swordfish` (fresh extent) and `Nika2007!` (2026-06 extent). Look for `successful login`.
- Live env for lanes: `GS_USER=DataCurator GS_PASS=<verified> GS_NETLDI_HOST=localhost GS_NETLDI_NAME_OR_PORT=gs64ldi GS_STONE=gs64stone OKZ_GEMSTONE_HOST_USERNAME=tariq OKZ_GEMSTONE_HOST_PASSWORD=Nika2007`.
  **Unset the shell's `GS_USERNAME`/`GS_PASSWORD`** — lane_common.sh normalizes them in and a stale one silently poisons live tests.

## Build a fully-loaded work image
```
GBS_KEEP_WORK_IMAGES=1 make full     # leaves "Pharo 14.0 - clean - cleanreload.image"
```

## Drive the bridge (login → evaluate → proxy → logout)
Write a plain-text `.st` script and run:
```
cd "<image dir>" && HOME=/tmp/pharo-clean-auto/home "<VM>" --headless "<work>.image" st script.st
```
User-facing API worth driving: `GbsSessionParameters new ... yourself` then `login` /
`GbsSessionParameters currentSession evaluate: '<gemstone code>'` (returns materialized
values / GbsTypedProxy for collections) / `logout`. Thread-safe path:
`loginThreadSafe` / `evaluateAndFetchStringThreadSafe:` / `logoutThreadSafe`.
Do NOT use `evaluateAndFetchString:` for non-string results — it returns `''`.

## Gotchas (each cost real time)
1. **One fresh image copy = one usable run, and it's the SECOND boot.** Lane images are
   saved mid-`snapshot:andQuit:`; the first boot of a copy resumes that save and quits
   before your script runs (silently). Each `st` run also re-saves, so a third boot
   replays the previous run's output. Protocol: copy master → boot once discarding
   output → boot again for the real run → delete the copy.
2. **`.st` chunk format treats `!` as a separator** — a literal `!` inside a string
   (e.g. the `Nika2007!` password) breaks the file silently. Compose via
   `(Character value: 33)` or read from env.
3. **Print via `Stdio stdout` (Pharo 14; `FileStream` is gone) or `Transcript show:`** —
   both reach the terminal.
4. Declare ALL temps in one `| ... |` at the top — mid-file `| x |` is a syntax error
   and the whole file dies silently.
5. Wrong GS password makes GciTs (thread-safe) tests ERROR while classic-GCI live tests
   silently skip — asymmetric symptom of the same cause.
6. VM: `vms/140-x64/Pharo.app` must be ≥ v10.3.9 for Pharo 14 (10.3.8 fails with
   "Cannot generate UUID" on first settings persistence, i.e. any clean-image lane run).
