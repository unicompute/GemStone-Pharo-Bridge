# Load Matrix

Generated from `GemStonePharoContract` group and lane contracts.

| Load group | Base prod | Base tests | Core overlay | Core tools | Core tests | MagLev overlay | MagLev tools | MagLev tests | Typical use |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Original` | yes | no | no | no | no | no | no | no | original/base production packages only |
| `Original-Tests` | yes | yes | no | no | no | no | no | no | original/base production packages plus the original/base test layer |
| `Core` | yes | no | yes | no | no | no | no | no | Smalltalk core bridge only |
| `Core-Tools` | yes | no | yes | yes | no | no | no | no | Smalltalk core plus the original Pharo tools and the generic core-tools overlay |
| `Core-Tests` | yes | no | yes | yes | yes | no | no | no | Smalltalk core, generic tool overlays, and the core-only test suite |
| `MagLev` | yes | no | yes | yes | no | yes | yes | no | convenience alias for the MagLev production stack |
| `Full` | yes | yes | yes | yes | yes | yes | yes | yes | full developer load |

## Switch Recipes

- base/original bridge: `Original`
- base/original bridge with base tests: `Original-Tests`
- base plus generic Smalltalk overlay: `Core`, `Core-Tools`, `Core-Tests`
- base plus generic overlay plus optional MagLev production: `MagLev`
- full developer load: `Full` / `default`

See [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md) for exact package membership and [VERIFICATION-LANES.md](./VERIFICATION-LANES.md) for the proof lanes that exercise these loads.
