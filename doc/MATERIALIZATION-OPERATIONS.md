# Materialization Operations

This note documents the operational knobs and evidence emitted by the GemStone object materialization path.

## Fetch Modes

- `fetchLegacy` materializes arrays recursively and leaves other non-scalar objects as proxies.
- `fetchShallow` materializes the selected root collection and returns proxies for nested collections.
- `fetchDeep` materializes supported nested collections across graph frontiers.
- `fetchByReference` returns proxies, using typed wrappers when a server class maps to one.

Supported scalar materialization currently includes strings, symbols, `DateTime`, and `ByteArray`. Supported collection materialization includes arrays, sequenceable collections, sets, dictionaries, and associations.

## Metrics

Each `fetchObject:` resets `session materializationMetrics`. The metrics dictionary is also cleared on logout/reconnect reset.

Common timing metrics:

- `rootFetchMs`: top-level fetch wall time.
- `fetchTotalMs`: total materialization wall time.
- `slotFetchMs`: single-array GCI or fallback slot fetch time.
- `frontierSlotFetchMs`: batched deep-frontier array slot fetch time.
- `collectionArrayBatchMs`: batched `asArray` conversion time for non-Array collections.
- `dictionaryPairBatchMs`: batched dictionary association-pair fetch time.
- `associationPairBatchMs`: batched association key/value fetch time.
- `scalarStringBatchMs`: batched string/symbol/date-time value fetch time.
- `scalarByteArrayBatchMs`: batched byte-array value fetch time.
- `classNameBatchMs`: remote class-name batch time.
- `proxyConstructionMs`: proxy construction time.
- `wrapperLookupMs`: typed-wrapper lookup time.

Common count metrics:

- `slotBatchCalls`, `slotBatchOopCount`: GCI slot batches for individual arrays.
- `frontierSlotBatchCalls`, `frontierSlotBatchObjectCount`, `frontierSlotBatchOopCount`: batched deep-frontier array slot fetches.
- `frontierSlotBatchFallbacks`, `frontierSlotBatchSplits`, `frontierSlotFallbackCalls`: adaptive fallback behavior for deep-frontier slot batches.
- `collectionArrayBatchCalls`, `collectionArrayBatchObjectCount`: batched conversion of ordered collections, sets, and bags to array snapshots.
- `dictionaryPairBatchCalls`, `dictionaryPairBatchObjectCount`, `dictionaryPairBatchPairCount`: batched dictionary association-pair fetches.
- `associationPairBatchCalls`, `associationPairBatchObjectCount`: batched association key/value fetches.
- `scalarStringBatchCalls`, `scalarStringBatchObjectCount`: batched scalar text fetches for strings, symbols, and date-times.
- `scalarByteArrayBatchCalls`, `scalarByteArrayBatchObjectCount`: batched byte-array fetches.
- `classNameBatchCalls`, `classNameBatchOopCount`: class-name batch calls and requested object count.
- `classNameBatchFallbacks`, `classNameBatchSplits`, `classNameFallbackCalls`: adaptive fallback behavior for class-name batches.
- `proxyCreations`, `proxyCacheHits`: proxy identity-map behavior.
- `wrapperLookupCalls`: typed-wrapper lookup count.

## Batch Tuning

Set `GBS_MATERIALIZATION_BATCH_SIZE` before launching Pharo, or set the Smalltalk global `GbsMaterializationBatchSize`, to cap the number of OOPs sent in each remote batch. Invalid or non-positive values fall back to `1000`.

Large class-name and deep-frontier slot batches are retried adaptively. If a batch fails, the reader splits it in half recursively until the split succeeds or a single object must use the older per-object fallback. Watch `classNameBatchSplits`, `frontierSlotBatchSplits`, and the corresponding fallback counters when tuning this value.

## Live Performance Lane

Run the live materialization benchmark with:

```bash
make materialization-perf
```

Required live environment:

- `GS_USER`
- `GS_PASS`
- `GEMSTONE`

Optional live environment:

- `GS_STONE`, default `gs64stone`
- `GS_SERVICE`, default `gemnetobject`
- `GS_NETLDI_HOST`
- `GS_NETLDI_NAME_OR_PORT`
- `OKZ_GEMSTONE_HOST_USERNAME`, when netldi host authentication is required
- `OKZ_GEMSTONE_HOST_PASSWORD`, when netldi host authentication is required
- `GBS_MATERIALIZATION_ARRAY_SIZE`, default `1200`
- `GBS_MATERIALIZATION_DICTIONARY_SIZE`, default `700`
- `GBS_MATERIALIZATION_SHALLOW_SIZE`, default `500`
- `GBS_MATERIALIZATION_MIXED_SIZE`, default `120`
- `GBS_MATERIALIZATION_BUSINESS_SIZE`, default `80`
- `GBS_MATERIALIZATION_BATCH_SIZE`, default `1000`

The benchmark seeds deterministic fixtures under `UserGlobals at: #GbsMaterializationPerfFixture` inside the active transaction. It covers arrays, dictionaries, shallow nested arrays, a mixed graph with ordered collections, sets, byte arrays, repeated references, and a larger business-shaped graph with dictionaries, associations, typed wrapper candidates, cycles, byte arrays, and strings. Unsupported objects should remain proxies. The lane removes the key before setup and aborts the transaction during cleanup, so fixture objects should not be committed.

## Thresholds And Drift

Absolute thresholds can be set directly or through `scripts/materialization_performance_thresholds.env`:

- `GBS_MATERIALIZATION_ARRAY_MAX_MS`
- `GBS_MATERIALIZATION_DICTIONARY_MAX_MS`
- `GBS_MATERIALIZATION_SHALLOW_MAX_MS`
- `GBS_MATERIALIZATION_MIXED_MAX_MS`
- `GBS_MATERIALIZATION_BUSINESS_MAX_MS`
- `GBS_MATERIALIZATION_CLAMPED_MAX_MS`
- `GBS_MATERIALIZATION_SHALLOW_WRAPPER_MAX_MS`
- `GBS_MATERIALIZATION_SHALLOW_WRAPPER_LOOKUP_MISSES_MAX`
- `GBS_MATERIALIZATION_MIXED_WRAPPER_LOOKUP_MISSES_MAX`
- `GBS_MATERIALIZATION_BUSINESS_WRAPPER_LOOKUP_MISSES_MAX`

Transport and round-trip thresholds can also be set through the same file. The maintained defaults require traversal-buffer fetches for shallow, mixed, and business fixtures, disallow old byte-payload fallbacks, and cap traversal-buffer report counts. The most important transport variables are:

- `GBS_MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN`
- `GBS_MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN`
- `GBS_MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN`
- `GBS_MATERIALIZATION_SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX`
- `GBS_MATERIALIZATION_MIXED_STRUCTURED_BYTE_FALLBACKS_MAX`
- `GBS_MATERIALIZATION_BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX`
- `GBS_MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MIN`
- `GBS_MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MAX`
- `GBS_MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX`

Trend drift is enforced when a previous trend sample exists:

- `GBS_MATERIALIZATION_PERF_REGRESSION_PERCENT`, default `35`
- `GBS_MATERIALIZATION_PERF_REGRESSION_MIN_DELTA_MS`, default `50`
- `GBS_MATERIALIZATION_PERF_TRENDS`, optional explicit trend JSONL path

The current sample may exceed the previous sample by the configured percentage or by the minimum millisecond delta, whichever is larger. The lane checks top-level array, dictionary, shallow, mixed-graph, business-graph, and clamped traversal timings plus shallow root, slot, class-name batch, proxy, wrapper submetrics, transport counts, clamped traversal-buffer usage, clamped fallback counts, and wrapper lookup misses.

## Replication And Lifecycle Policies

`GbsSettingsPresenter` exposes the production policy fields that feed `GbsReplicationPolicy` and session lifecycle behavior:

- `autoMarkDirty`: enables dirty marking for materialized mutable objects unless a clamp scheme overrides it.
- `blockReplicationPolicy`: `replicate`, `callback`, `stub`, or `none`.
- `defaultFaultPolicy`: `lazy`, `immediate`, `eager`, or `none`; `eager` normalizes to `immediate` in the policy object.
- `faultLevelRpc`: RPC fault depth used by compatibility paths.
- `freeOopBatchSize`: maximum queued GC/export-set OOPs drained in one lifecycle batch; `0` drains nothing.
- `freeSlotsOnStubbing`: allows stub/fault transitions to release local slots where supported.
- `serverMapMode`: `weak` keeps a weak materialized-object map, `strong` keeps mapped replicates until explicitly forgotten or session reset.
- `storeTraversalTransport`: `script`, `binary`, or `binaryRequired` for dirty-write traversal flushing. The binary path uses native `GciStoreTravDoTravRefs_` argument buffers to hand off queued no-longer-replicated and GCed OOPs when the native server interface exposes that transport.
- `traversalBufferSize`: GCI traversal-buffer size for fetch-side traversal.
- `asyncSignalPollingEnabled`, `eventPollingFrequency`, and `eventPriority`: async signal polling controls.

Use `session objectSpace lifecycleReport` or `session objectSpace lifecycleReportText` to inspect the current server-map size, queued GC OOPs, queued no-longer-replicated OOPs, the combined export-set release queue size, the active free-OOP drain limit, whether native release-OOP transport is available, and whether dirty store traversal can carry no-longer-replicated OOPs. The classic launcher exposes the same diagnostic as `Session Lifecycle Report`.

Use `(GbsReplicationPolicy forSession: session) reportText` to inspect the active replication/faulting policy. The classic launcher exposes the same diagnostic as `Replication Policy Report`.

The lifecycle facade exposes two levels of release coordination:

- `session objectSpace pendingGcedOops` and `pendingNoLongerReplicatedOops` show the next queued release candidates without mutating the queues.
- `session objectSpace pendingExportSetReleaseOops` returns both queues together for native dirty-store traversal diagnostics.
- `session objectSpace flushGcedOops` releases GC'd exported OOPs through `GciReleaseOops` and removes them locally only after the native call succeeds.
- `session objectSpace flushExportSetReleaseOops` releases GC'd OOPs through `GciReleaseOops` and reports queued no-longer-replicated OOPs separately. When a binary dirty-store traversal runs against a server interface that supports native `GciStoreTravDoTravRefs_` handoff, both queued no-longer-replicated and GCed OOPs are passed with the dirty traversal and are removed locally only after the native call succeeds.
- `session objectSpace flushExportSetReleaseOopsReportText` returns the same flush summary in launcher-friendly text. The classic launcher exposes this as `Flush GC Exported OOPs`.

`GbsClientClassConnector` provides the Pharo compatibility surface for VisualWorks-style client/server class connector setup. Installing one in a session's `GbxReplicatorManager` registers the connector pair with `GbsSessionManager`, marks the pair connected for that session, installs a converted replicator in the client/server maps, and updates the active clamp scheme from per-instvar replication specs or a `#callback` clamp spec. The replicator-manager report includes connected/disconnected connector-pair counts and per-pair post-connect actions; direct manager removal clears the session connector pair and connection-state registry entry.

Use `session dirtyStoreTraversalReport` after `session flushDirtyMaterializedObjects` to inspect the write-path split. The report includes total dirty entries, native binary entries/flushes, remote command entries, semantic command count, Dictionary/Set/Bag semantic entry counts, and custom semantic entry counts for objects that opt into `gbsDirtyStoreRequiresSemanticCommand`. `session resetMaterializedObjectDirtyTracking` clears this report.

## Live Replication Lane

Run the live connector/clamp/dirty-store validation with:

```bash
make replication-live
```

Required live environment is the same minimal set used by `make materialization-perf`: `GS_USER`, `GS_PASS`, and `GEMSTONE`. The usual optional stone, netldi, and host-auth environment variables are honored by the shared live preflight.

The lane validates four production-relevant paths against a real GemStone session:

- VisualWorks-style `GbsClientClassConnector` installation into the session replicator manager, including client/server maps and server clamp specification synchronization.
- Strict parity fixtures for static per-instvar clamp metadata, server callback clamp selector synchronization, and inherited named replication-spec selectors.
- A migration-domain fixture that creates live GemStone order/customer classes, installs a five-slot Pharo domain connector with forwarder/min/max/stub/nil slot policy, verifies the server callback clamp selector, and flushes named-slot dirty writes through native store traversal buffers.
- Clamped Association materialization through `GciClampedTrav`, with traversal-buffer fallback count required to remain zero.
- Mixed dirty-store traversal for a migration-shaped root graph, with Array, Association, OrderedCollection, and named-slot mutations using native dirty-store buffers where safe, while Dictionary, Set, and Bag mutations are flushed through a batched semantic server command. Exported OOP release queues are acknowledged only after the native store call succeeds.
- A larger business-write fixture with twelve materialized Array, Association, and OrderedCollection roots. The lane mutates all twelve, flushes them through the dirty-store traversal path, and verifies the remote fixture state before recording the write-path timing.

Thresholds are configured through `scripts/replication_live_thresholds.env` or direct `GBS_REPLICATION_LIVE_*` environment variables. The defaults require at least one callback clamp spec, at least one per-instvar clamp entry, at least one inherited replication-spec fixture, at least one migration-domain fixture, at least one domain callback clamp spec, at least one domain per-instvar clamp entry, at least two domain dirty objects flushed through native dirty-store buffers, at least one clamped traversal fetch, zero clamped fallbacks, at least one native dirty-store flush, at least one semantic dirty-store command, at least three semantic Dictionary/Set/Bag entries, at least six mixed dirty objects flushed, at least twelve business dirty objects flushed, and zero export-set release queue entries remaining after both flushes. Trend regression uses `GBS_REPLICATION_LIVE_REGRESSION_PERCENT` or `GBS_REPLICATION_LIVE_REGRESSION_MIN_DELTA_MS`, whichever allows the larger drift over the previous persisted sample.

## Artifacts

When `GBS_EVIDENCE_DIR` is set, the lane writes:

- `materialization-performance-preflight.log`
- `materialization-performance-baseline.log`
- `materialization-performance-summary.json`
- `materialization-performance-summary.md`
- `materialization-performance-trends.jsonl`
- `materialization-performance-trend-report.md`

The replication lane writes separate artifacts:

- `replication-live-preflight.log`
- `replication-live-validation.log`
- `replication-live-summary.json`
- `replication-live-summary.md`
- `replication-live-trends.jsonl`, when `GBS_REPLICATION_LIVE_TRENDS` or `GBS_EVIDENCE_DIR` is set
- `replication-live-trend-report.md`, when a replication trend path is available

Use the summary JSON for machine checks and the Markdown summary for CI job summaries. The materialization and replication live lanes also write trend reports for quick human review of the last 20 samples.

## Typed Wrapper Compatibility

Use `session typedWrapperCompatibilityReportText` or `GBSM typedWrapperCompatibilityReportText` to inspect wrapper compatibility. The report includes wrapper class, server class, server version, cached freshness decision, lifecycle status, and the invalidation reason.
