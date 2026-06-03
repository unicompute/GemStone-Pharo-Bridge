# VW/VAST Replication Parity Notes

This note records the current cross-reference against the sibling VisualWorks and VAST GemStone implementations for replication behavior, dirty-store traversal, and connector policy.

## Reference Trees

- `/Users/tariq/src/gemtools/Visualworks-Gemstone`
- `/Users/tariq/src/gemtools/gemstone_vast`

## Confirmed VisualWorks Semantics

The VisualWorks implementation treats `replicationSpec` as both a client-side replication policy and a source for clamped traversal metadata. The important operators observed in `GbsKernelBaseExt.st` are:

- `replicate`: materialize the slot.
- `stub`: exclude the slot from transitive closure.
- `min` and `max`: depth controls, also excluded from transitive closure specs.
- `forwarder`: leave the slot as a forwarder/proxy.
- `indexable_part`: policy for indexed slots in variable-sized objects.
- `callback`: use server-side callback policy rather than a static instvar-level table.

`GbxReplicationScheme >> transitiveClosureSpecForReplicationSpec:` now preserves the VW filtering rule: `min`, `max`, and `stub` entries are removed, while `replicate`, `forwarder`, and `indexable_part` entries remain. `#callback` produces an empty static transitive closure spec.

## Implemented Pharo Coverage

- `GbsClientClassConnector` installs a converted replicator into the session replicator manager, registers the client/server pair, and updates clamp metadata from per-instvar replication specs.
- `GbsServerClampSpecificationSynchronizer` installs a server `ClampSpecification` for live clamped traversal.
- `GbsDirtyReplicateStoreTraversal` can use native dirty-store buffers and native `GciStoreTravDoTravRefs_` coordination for queued no-longer-replicated and GCed OOPs.
- `GbsSessionLifecycleManager` tracks session server maps, no-longer-replicated queues, GCed OOP queues, finalizer tokens, and release transport availability.
- `make replication-live` validates connector install, server clamp synchronization, clamped traversal, native dirty-store flush, and export-set queue acknowledgement against a live GemStone session.

## Remaining Parity Watchpoints

- Full VisualWorks server-side callback behavior for class-specific clamp hooks still needs broader live coverage beyond Association.
- Per-instvar traversal semantics should be validated against domain classes with explicit `instVarMap` nil mappings and inherited replication specs.
- VAST `faultLevelRpc` compatibility is represented in the policy surface, but deeper fault transition behavior still needs migration-shaped live tests.
- The native dirty-store buffer currently covers mapped Arrays, Associations, and OrderedCollections. Dictionaries, Sets, Bags, and custom domain objects still use script or higher-level conversion paths.
- Strict VisualWorks-style client-class connector manager behavior is approximated in Pharo's converted replicator manager; a complete VW replicator-manager clone remains future work if exact parity is required.
