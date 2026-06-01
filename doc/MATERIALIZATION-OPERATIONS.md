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
- `GBS_MATERIALIZATION_ARRAY_SIZE`, default `1200`
- `GBS_MATERIALIZATION_DICTIONARY_SIZE`, default `700`
- `GBS_MATERIALIZATION_SHALLOW_SIZE`, default `500`
- `GBS_MATERIALIZATION_MIXED_SIZE`, default `120`
- `GBS_MATERIALIZATION_BATCH_SIZE`, default `1000`

The benchmark seeds deterministic fixtures under `UserGlobals at: #GbsMaterializationPerfFixture` inside the active transaction. It covers arrays, dictionaries, shallow nested arrays, and a mixed graph with ordered collections, sets, byte arrays, repeated references, and an unsupported object that should remain a proxy. The lane removes the key before setup and aborts the transaction during cleanup, so fixture objects should not be committed.

## Thresholds And Drift

Absolute thresholds can be set directly or through `scripts/materialization_performance_thresholds.env`:

- `GBS_MATERIALIZATION_ARRAY_MAX_MS`
- `GBS_MATERIALIZATION_DICTIONARY_MAX_MS`
- `GBS_MATERIALIZATION_SHALLOW_MAX_MS`
- `GBS_MATERIALIZATION_MIXED_MAX_MS`

Trend drift is enforced when a previous trend sample exists:

- `GBS_MATERIALIZATION_PERF_REGRESSION_PERCENT`, default `35`
- `GBS_MATERIALIZATION_PERF_REGRESSION_MIN_DELTA_MS`, default `50`
- `GBS_MATERIALIZATION_PERF_TRENDS`, optional explicit trend JSONL path

The current sample may exceed the previous sample by the configured percentage or by the minimum millisecond delta, whichever is larger. The lane checks top-level array, dictionary, shallow, and mixed-graph timings plus shallow root, slot, class-name batch, proxy, and wrapper submetrics.

## Artifacts

When `GBS_EVIDENCE_DIR` is set, the lane writes:

- `materialization-performance-preflight.log`
- `materialization-performance-baseline.log`
- `materialization-performance-summary.json`
- `materialization-performance-summary.md`
- `materialization-performance-trends.jsonl`
- `materialization-performance-trend-report.md`

Use the summary JSON for machine checks, the Markdown summary for CI job summaries, and the trend report for quick human review of the last 20 samples.

## Typed Wrapper Compatibility

Use `session typedWrapperCompatibilityReportText` or `GBSM typedWrapperCompatibilityReportText` to inspect wrapper compatibility. The report includes wrapper class, server class, server version, cached freshness decision, lifecycle status, and the invalidation reason.
