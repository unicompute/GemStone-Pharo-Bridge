| loadFailed supportClass proxyClass session env integerEnv millisecondsToRun metricValue arraySize dictionarySize shallowSize mixedSize arrayOop dictionaryOop shallowOop mixedOop arrayResult dictionaryResult shallowResult mixedResult arrayMs dictionaryMs shallowMs mixedMs shallowMetrics mixedMetrics fixtureKey cleanupFixture phase |
[
  loadFailed := false.
  cleanupFixture := [ ].
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        loadFailed := true.
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  loadFailed ifTrue: [
    Transcript
      show: 'MATERIALIZATION_PERF_BASELINE result=FAIL code=MATERIALIZATION_PERF_LOAD_FAILED array_ms=0 dictionary_ms=0 shallow_ms=0 array_size=0 dictionary_size=0 shallow_size=0';
      cr ] ifFalse: [
    [
      env := [ Smalltalk os environment ]
        on: Error
        do: [ Dictionary new ].
      integerEnv := [ :name :default |
        | raw value |
        raw := env at: name ifAbsent: [ default asString ].
        value := [ raw asString asInteger ] on: Error do: [ default ].
        value <= 0 ifTrue: [ default ] ifFalse: [ value ] ].
      millisecondsToRun := [ :block |
        | start elapsed |
        start := Time millisecondClockValue.
        block value.
        elapsed := Time millisecondClockValue - start.
        elapsed < 0 ifTrue: [ elapsed := elapsed + 86400000 ].
        elapsed ].
      metricValue := [ :metrics :key |
        metrics
          at: key
          ifAbsent: [ 0 ] ].
      phase := 'initializing'.

      arraySize := integerEnv value: 'GBS_MATERIALIZATION_ARRAY_SIZE' value: 1200.
      dictionarySize := integerEnv value: 'GBS_MATERIALIZATION_DICTIONARY_SIZE' value: 700.
      shallowSize := integerEnv value: 'GBS_MATERIALIZATION_SHALLOW_SIZE' value: 500.
      mixedSize := integerEnv value: 'GBS_MATERIALIZATION_MIXED_SIZE' value: 120.
      fixtureKey := #GbsMaterializationPerfFixture.

      supportClass := Smalltalk
        at: #GbsLiveSessionTestSupport
        ifAbsent: [ Smalltalk at: #CoreGbsLiveSessionTestSupport ifAbsent: [ nil ] ].
      supportClass ifNil: [
        Error signal: 'Missing live session support class.' ].
      proxyClass := Smalltalk at: #GbsProxy ifAbsent: [ nil ].
      proxyClass ifNil: [
        Error signal: 'Missing proxy class.' ].
      session := supportClass ensureSharedSession.
      (supportClass sessionIsUsable: session) ifFalse: [
        Error signal: supportClass unavailableReason ].
      cleanupFixture := [
        session ifNotNil: [
          [ session
              fetchRemoteCommandBody: 'UserGlobals removeKey: fixtureKey ifAbsent: [ nil ]. nil'
              literalBindings: (Dictionary new
                at: 'fixtureKey' put: fixtureKey;
                yourself)
              oopBindings: Dictionary new
              context: 20 ]
            on: Error
            do: [ ] ] ].

      [
        phase := 'cleanup-before-fixtures'.
        cleanupFixture value.
        phase := 'array-fixture'.
        arrayOop := session
          returnRemoteCommandBody: '| fixture array |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
array := Array new: size.
1 to: size do: [ :index | array at: index put: index ].
fixture at: #array put: array.
array'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'size' put: arraySize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        phase := 'array-fetch-mode'.
        session fetchDeep.
        phase := 'array-materialization'.
        arrayMs := millisecondsToRun value: [
          arrayResult := session fetchObject: arrayOop ].
        ((arrayResult size = arraySize)
          and: [ arrayResult first = 1
          and: [ arrayResult last = arraySize ] ]) ifFalse: [
            Error signal: 'Array materialization produced an unexpected result.' ].

        phase := 'dictionary-fixture'.
        dictionaryOop := session
          returnRemoteCommandBody: '| fixture dictionary |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
dictionary := Dictionary new.
1 to: size do: [ :index | dictionary at: index put: index + size ].
fixture at: #dictionary put: dictionary.
dictionary'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'size' put: dictionarySize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        phase := 'dictionary-fetch-mode'.
        session fetchDeep.
        phase := 'dictionary-materialization'.
        dictionaryMs := millisecondsToRun value: [
          dictionaryResult := session fetchObject: dictionaryOop ].
        ((dictionaryResult size = dictionarySize)
          and: [ (dictionaryResult at: 1) = (dictionarySize + 1)
          and: [ (dictionaryResult at: dictionarySize) = (dictionarySize * 2) ] ]) ifFalse: [
            Error signal: 'Dictionary materialization produced an unexpected result.' ].

        phase := 'shallow-fixture'.
        shallowOop := session
          returnRemoteCommandBody: '| fixture root |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
root := Array new: size.
1 to: size do: [ :index | root at: index put: (Array with: index with: index + 1) ].
fixture at: #shallow put: root.
root'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'size' put: shallowSize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        phase := 'shallow-fetch-mode'.
        session fetchShallow.
        phase := 'shallow-materialization'.
        shallowMs := millisecondsToRun value: [
          shallowResult := session fetchObject: shallowOop ].
        shallowMetrics := session materializationMetrics copy.
        ((shallowResult size = shallowSize)
          and: [ (shallowResult first isKindOf: proxyClass)
          and: [ shallowResult last oop notNil ] ]) ifFalse: [
            Error signal: 'Shallow materialization produced an unexpected result.' ].

        phase := 'mixed-fixture'.
        mixedOop := session
          returnRemoteCommandBody: '| fixture root shared ordered nestedSet nestedDictionary bytes unsupported customers orders catalog |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
shared := Array with: ''shared'' with: (ByteArray withAll: #(1 2 3 4)).
ordered := OrderedCollection new.
1 to: size do: [ :index |
  ordered add: (Array with: index asString with: shared) ].
nestedSet := Set new.
nestedSet add: shared; add: ''marker''.
nestedDictionary := Dictionary new.
nestedDictionary
  at: #shared put: shared;
  at: #set put: nestedSet.
bytes := ByteArray withAll: #(5 6 7).
unsupported := Object new.
customers := OrderedCollection new.
orders := OrderedCollection new.
catalog := Dictionary new.
1 to: (size max: 10) do: [ :index |
  | customer order lines tags payload address sku product |
  sku := ''SKU-'', index printString.
  payload := ByteArray withAll: {
    index \\ 256.
    (index + 1) \\ 256.
    (index + 2) \\ 256 }.
  tags := Set new.
  tags
    add: #active;
    add: (''segment-'', (index \\ 5) printString);
    add: shared.
  address := Dictionary new.
  address
    at: #city put: (''City '', index printString);
    at: #postalCode put: (''PC'', index printString).
  lines := OrderedCollection new.
  lines
    add: (Association key: sku value: shared);
    add: (Association key: #payload value: payload).
  customer := Dictionary new.
  customer
    at: #id put: index;
    at: #name put: (''Customer '', index printString);
    at: #tags put: tags;
    at: #address put: address;
    at: #payload put: payload;
    at: #shared put: shared.
  order := Dictionary new.
  order
    at: #customer put: customer;
    at: #lines put: lines;
    at: #status put: #open;
    at: #notes put: (''Order '', index printString).
  product := Dictionary new.
  product
    at: #name put: (''Product '', index printString);
    at: #payload put: payload;
    at: #shared put: shared.
  customers add: customer.
  orders add: order.
  catalog at: sku put: product ].
root := Dictionary new.
root
  at: #ordered put: ordered;
  at: #dictionary put: nestedDictionary;
  at: #bytes put: bytes;
  at: #proxy put: unsupported;
  at: #again put: shared;
  at: #customers put: customers;
  at: #orders put: orders;
  at: #catalog put: catalog.
fixture at: #mixed put: root.
root'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'size' put: mixedSize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        phase := 'mixed-fetch-mode'.
        session fetchDeep.
        phase := 'mixed-materialization'.
        mixedMs := millisecondsToRun value: [
          mixedResult := session fetchObject: mixedOop ].
        mixedMetrics := session materializationMetrics copy.
        phase := 'mixed-verification'.
        (((mixedResult at: #ordered) size = mixedSize)
          and: [ ((mixedResult at: #ordered) first second) == (mixedResult at: #again)
          and: [ ((mixedResult at: #bytes) = (ByteArray withAll: #(5 6 7)))
          and: [ ((mixedResult at: #proxy) isKindOf: proxyClass)
          and: [ (((mixedResult at: #customers) first at: #shared) == (mixedResult at: #again))
          and: [ ((((mixedResult at: #orders) first at: #lines) first value) == (mixedResult at: #again))
          and: [ (((mixedResult at: #customers) first at: #payload) isKindOf: ByteArray) ] ] ] ] ] ]) ifFalse: [
            Error signal: 'Mixed graph materialization produced an unexpected result.' ].

        Transcript
          show: 'MATERIALIZATION_PERF_BASELINE result=OK code=MATERIALIZATION_PERF_OK',
            ' array_ms=', arrayMs asString,
            ' dictionary_ms=', dictionaryMs asString,
            ' shallow_ms=', shallowMs asString,
            ' mixed_ms=', mixedMs asString,
            ' array_size=', arraySize asString,
            ' dictionary_size=', dictionarySize asString,
            ' shallow_size=', shallowSize asString,
            ' mixed_size=', mixedSize asString,
            ' shallow_root_ms=', (metricValue value: shallowMetrics value: #rootFetchMs) asString,
            ' shallow_slot_ms=', (metricValue value: shallowMetrics value: #slotFetchMs) asString,
            ' shallow_class_name_batch_ms=', (metricValue value: shallowMetrics value: #classNameBatchMs) asString,
            ' shallow_proxy_ms=', (metricValue value: shallowMetrics value: #proxyConstructionMs) asString,
            ' shallow_wrapper_ms=', (metricValue value: shallowMetrics value: #wrapperLookupMs) asString,
            ' shallow_slot_batches=', (metricValue value: shallowMetrics value: #slotBatchCalls) asString,
            ' shallow_class_name_batches=', (metricValue value: shallowMetrics value: #classNameBatchCalls) asString,
            ' shallow_proxy_creations=', (metricValue value: shallowMetrics value: #proxyCreations) asString,
            ' shallow_wrapper_lookups=', (metricValue value: shallowMetrics value: #wrapperLookupCalls) asString,
            ' shallow_wrapper_cache_hits=', (metricValue value: shallowMetrics value: #wrapperCacheHits) asString,
            ' shallow_wrapper_lookup_misses=', (metricValue value: shallowMetrics value: #wrapperLookupMisses) asString,
            ' shallow_wrapper_typed_results=', (metricValue value: shallowMetrics value: #wrapperLookupTypedResults) asString,
            ' shallow_wrapper_nil_results=', (metricValue value: shallowMetrics value: #wrapperLookupNilResults) asString,
            ' shallow_structured_byte_fetches=', (metricValue value: shallowMetrics value: #structuredBatchByteFetchCalls) asString,
            ' shallow_structured_traversal_byte_fetches=', (metricValue value: shallowMetrics value: #structuredTraversalByteFetchCalls) asString,
            ' shallow_structured_traversal_buffer_fetches=', (metricValue value: shallowMetrics value: #structuredTraversalBufferFetchCalls) asString,
            ' shallow_structured_traversal_buffer_reports=', (metricValue value: shallowMetrics value: #structuredTraversalReportCount) asString,
            ' shallow_structured_byte_fallbacks=', ((metricValue value: shallowMetrics value: #structuredByteBatchFallbacks) + (metricValue value: shallowMetrics value: #structuredTraversalByteFallbacks) + (metricValue value: shallowMetrics value: #structuredTraversalBufferFallbacks)) asString,
            ' mixed_collection_array_batches=', (metricValue value: mixedMetrics value: #collectionArrayBatchCalls) asString,
            ' mixed_dictionary_pair_batches=', (metricValue value: mixedMetrics value: #dictionaryPairBatchCalls) asString,
            ' mixed_scalar_string_batches=', (metricValue value: mixedMetrics value: #scalarStringBatchCalls) asString,
            ' mixed_scalar_byte_array_batches=', (metricValue value: mixedMetrics value: #scalarByteArrayBatchCalls) asString,
            ' mixed_wrapper_cache_hits=', (metricValue value: mixedMetrics value: #wrapperCacheHits) asString,
            ' mixed_wrapper_lookup_misses=', (metricValue value: mixedMetrics value: #wrapperLookupMisses) asString,
            ' mixed_wrapper_typed_results=', (metricValue value: mixedMetrics value: #wrapperLookupTypedResults) asString,
            ' mixed_wrapper_nil_results=', (metricValue value: mixedMetrics value: #wrapperLookupNilResults) asString,
            ' mixed_structured_byte_fetches=', (metricValue value: mixedMetrics value: #structuredBatchByteFetchCalls) asString,
            ' mixed_structured_traversal_byte_fetches=', (metricValue value: mixedMetrics value: #structuredTraversalByteFetchCalls) asString,
            ' mixed_structured_traversal_buffer_fetches=', (metricValue value: mixedMetrics value: #structuredTraversalBufferFetchCalls) asString,
            ' mixed_structured_traversal_buffer_reports=', (metricValue value: mixedMetrics value: #structuredTraversalReportCount) asString,
            ' mixed_structured_byte_fallbacks=', ((metricValue value: mixedMetrics value: #structuredByteBatchFallbacks) + (metricValue value: mixedMetrics value: #structuredTraversalByteFallbacks) + (metricValue value: mixedMetrics value: #structuredTraversalBufferFallbacks)) asString;
          cr.
      ] ensure: [
        cleanupFixture value.
        [ session abortTransaction ] on: Error do: [ ].
        [ supportClass releaseOwnedSession ] on: Error do: [ ] ]
    ] on: Error do: [ :ex |
      Transcript
        show: 'MATERIALIZATION_PERF_BASELINE result=FAIL code=MATERIALIZATION_PERF_RUN_FAILED array_ms=0 dictionary_ms=0 shallow_ms=0 array_size=0 dictionary_size=0 shallow_size=0 message=';
        show: (ex messageText ifNil: [ ex printString ]) withBlanksTrimmed;
        show: ' phase=';
        show: (phase ifNil: [ 'unknown' ]);
        cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
