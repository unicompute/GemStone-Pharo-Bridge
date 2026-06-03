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

`GbxReplicationScheme >> transitiveClosureSpecForReplicationSpec:` now preserves the VW filtering rule: `min`, `max`, and `stub` entries are removed, while `replicate`, `forwarder`, and `indexable_part` entries remain. `#callback` produces an empty static transitive closure spec. Clamp-by-callback selector derivation also follows VW: each replication spec set uses `<replicationSpecSet>GbsClampCallback`, with `#transitiveClosureSpec` excluded.

## Implemented Pharo Coverage

- `GbsClientClassConnector` installs a converted replicator into the session replicator manager, registers the client/server pair, and updates clamp metadata from per-instvar replication specs. Reinstalling a connector for an already-mapped client or server removes the old replicator, secondary aliases, deferred server-instvar requests, clamp artefacts, and stale session connector pair before installing the replacement.
- `GbsServerClampSpecificationSynchronizer` installs a server `ClampSpecification` for live clamped traversal.
- `GbxReplicationScheme` validates clamp-by-callback selectors against live GemStone sessions via the mapped server behavior when available, with the original `Object canUnderstand:` path retained as the compatibility fallback before installing the selector into the server clamp specification.
- `GbsDirtyReplicateStoreTraversal` can use native dirty-store buffers and native `GciStoreTravDoTravRefs_` coordination for queued no-longer-replicated and GCed OOPs.
- Dirty-store traversal records a session-level write-path report showing native binary entries, semantic command entries, Dictionary/Set/Bag semantic counts, and custom semantic-policy counts for domain objects that opt into `gbsDirtyStoreRequiresSemanticCommand`. The live replication lane thresholds both native binary writes and semantic collection writes.
- `GbsSessionLifecycleManager` tracks session server maps, no-longer-replicated queues, GCed OOP queues, finalizer tokens, and release transport availability.
- `GbsSessionLifecycleManager` also records lifecycle counters for remembered/remapped OOPs, forgotten materialized objects, queued/acknowledged export-set OOPs, finalizer notifications, release-oops transport calls, and the last export-set flush summary. These counters are exposed through the session lifecycle report and thresholded in the live replication lane.
- `GbxReplicatorManager` now treats the replicator as the lifecycle unit for client aliases, server aliases, deferred server-instvar updates, and clamp artefacts, so secondary client mappings and server removals clean up consistently.
- `GbxReplicatorManager` exposes VW-style client-class connector compatibility entrypoints plus a structured connector-manager report covering client/server map sizes, connector-pair count, connected/disconnected session pair counts, post-connect actions, deferred server-instvar work, active behavior names, replication-spec set, and clamp count. The launcher includes this report next to the replication policy and lifecycle reports.
- `GbsClassConnector` connect now registers the concrete connector object before manager installation, so connector subclass type, session connection state, and post-connect action survive the Pharo `GbsClientClassConnector` bridge. Direct replicator-manager removal also unregisters session connector pairs and connection-state registry entries, matching the connector disconnect lifecycle.
- `GbxClampManager` now updates callback metadata, named replication schemes, class-shape/class-version refreshes, and removal cleanup across all known schemes instead of only the currently active scheme. Named schemes ask the client class for the selected replication-spec selector when it exists, so `#customerReplicationSpec` and `#callbackReplicationSpec` no longer silently reuse only the default `#replicationSpec`, including when the selector is inherited.
- Explicit materialized-object stubbing and fault refresh are available through session/object-space APIs. Stubbing evicts materialized identity caches, unregisters dirty/server-map state, optionally frees local slots according to `freeSlotsOnStubbing`, and queues no-longer-replicated OOPs only for real local replicates. Faulting through a proxy fetches a fresh replicate and cancels a pending no-longer-replicated release for that OOP.
- `make replication-live` validates connector install, connector-manager report counts, server clamp synchronization, callback clamp selector synchronization, per-instvar clamp entries, inherited named replication specs, a live migration-domain order/customer fixture with forwarder/min/max/stub/nil slot policy, native named-slot dirty writes for that domain fixture, clamped traversal, native dirty-store flush, lifecycle queued/acknowledged export-set counters, a twelve-object business-write dirty traversal fixture, export-set queue acknowledgement, and trend thresholds against a live GemStone session.

## Remaining Parity Watchpoints

- Broader migration-shaped live callback coverage is still useful for real application domain classes that implement their own `<replicationSpecSet>GbsClampCallback` methods beyond the built-in order/customer fixture.
- Per-instvar traversal semantics are live-validated for a five-slot order fixture with an omitted/nil policy slot; strict application parity should still be checked against real `instVarMap` methods from migration projects.
- VAST `faultLevelRpc` compatibility is represented in the policy surface, but deeper fault transition behavior still needs migration-shaped live tests.
- The native dirty-store buffer currently covers mapped Arrays, Associations, OrderedCollections, and named-slot objects with OOP-addressable values. Dictionaries, Sets, and Bags are covered by the batched semantic command path and live thresholds, but not by native binary object reports. Custom/domain objects needing richer semantic policy can force the semantic command path with `gbsDirtyStoreRequiresSemanticCommand`.
- A complete VisualWorks replicator-manager clone may still expose deeper inherited server callback behavior and connector subclass policy edge cases, but the Pharo manager now covers the core connector alias, replacement, removal, deferred-instvar, class-version refresh, selector-driven named scheme, and multi-scheme clamp lifecycle semantics.
