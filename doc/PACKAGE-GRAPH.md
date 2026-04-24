# Package Graph

Generated from `GemStonePharoContract` package and lane contracts.

Rendered SVG: [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)

## Packages

- `GemStone-GBS-Converted`
  requires: `(none)`
- `GemStone-GBS-Core`
  requires: `GemStone-GBS-Converted`
- `GemStone-GBS-Tools`
  requires: `GemStone-GBS-Converted`
- `GemStone-GBS-Core-Tools`
  requires: `GemStone-GBS-Core`, `GemStone-GBS-Tools`
- `GemStone-GBS-MagLev`
  requires: `GemStone-GBS-Converted`, `GemStone-GBS-Core`
- `GemStone-GBS-MagLev-Tools`
  requires: `GemStone-GBS-Tools`, `GemStone-GBS-MagLev`
- `GemStone-Pharo-Core-Tests`
  requires: `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`
- `GemStone-Pharo-MagLev-Tests`
  requires: `GemStone-Pharo-Core-Tests`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `GemStone-Pharo-Tests`
  requires: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`

## Load Groups

- `Original` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- `Original-Tests` -> `GemStone-GBS-Converted`, `GemStone-GBS-Tools`, `GemStone-Pharo-Tests`
- `Core` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`
- `Core-Only` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`
- `Core-Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`
- `Core-Tests` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`, `GemStone-Pharo-Core-Tests`
- `MagLev-Core` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-MagLev`
- `MagLev-Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `MagLev` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `Tools` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`
- `All-Tests` -> `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`, `GemStone-Pharo-Tests`
- `Tests` -> `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`, `GemStone-Pharo-Tests`
- `Full` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-MagLev`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev-Tools`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`, `GemStone-Pharo-Tests`
- `default` -> `GemStone-GBS-Converted`, `GemStone-GBS-Core`, `GemStone-GBS-MagLev`, `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev-Tools`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`, `GemStone-Pharo-Tests`

## Forbidden Reverse Dependencies

- `GemStone-GBS-Tools` must not require `GemStone-GBS-Core`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `GemStone-Pharo-Core-Tests` must not require `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- `GemStone-GBS-Converted` must not require `GemStone-GBS-Core`, `GemStone-GBS-Core-Tools`, `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`, `GemStone-GBS-Tools`
