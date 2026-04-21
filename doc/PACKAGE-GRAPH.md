# Package Graph

Generated from `GemStonePharoContract` package and lane contracts.

Rendered SVG: [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)

## Packages

- `GemStone-GBS-Converted`
  requires: `(none)`
- `GemStone-GBS-MagLev`
  requires: `GemStone-GBS-Converted`
- `GemStone-GBS-Tools`
  requires: `GemStone-GBS-Converted`
- `GemStone-GBS-MagLev-Tools`
  requires: `GemStone-GBS-Tools`, `GemStone-GBS-MagLev`
- `GemStone-Pharo-Core-Tests`
  requires: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- `GemStone-Pharo-Tests`
  requires: `GemStone-Pharo-Core-Tests`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`

## Load Groups

- `Core` -> `GemStone-GBS-Converted`
- `Core-Only` -> `GemStone-GBS-Converted`
- `Core-Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- `Core-Tests` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`, `GemStone-Pharo-Core-Tests`
- `MagLev-Core` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `MagLev-Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `MagLev` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- `All-Tests` -> `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`
- `Tests` -> `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`
- `Full` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`, `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`
- `default` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`, `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`

## Forbidden Reverse Dependencies

- `GemStone-GBS-Tools` must not require `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `GemStone-Pharo-Core-Tests` must not require `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `GemStone-GBS-Converted` must not require `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`, `GemStone-GBS-Tools`
