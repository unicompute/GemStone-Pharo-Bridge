| loadFailed supportClass proxyClass session env integerEnv millisecondsToRun arraySize dictionarySize shallowSize arrayOop dictionaryOop shallowOop arrayResult dictionaryResult shallowResult arrayMs dictionaryMs shallowMs |
[
  loadFailed := false.
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

      arraySize := integerEnv value: 'GBS_MATERIALIZATION_ARRAY_SIZE' value: 1200.
      dictionarySize := integerEnv value: 'GBS_MATERIALIZATION_DICTIONARY_SIZE' value: 700.
      shallowSize := integerEnv value: 'GBS_MATERIALIZATION_SHALLOW_SIZE' value: 500.

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

      [
        arrayOop := session
          returnRemoteCommandBody: '| array |
array := Array new: size.
1 to: size do: [ :index | array at: index put: index ].
array'
          literalBindings: (Dictionary new
            at: 'size' put: arraySize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        arrayMs := millisecondsToRun value: [
          arrayResult := session fetchObject: arrayOop ].
        ((arrayResult size = arraySize)
          and: [ arrayResult first = 1
          and: [ arrayResult last = arraySize ] ]) ifFalse: [
            Error signal: 'Array materialization produced an unexpected result.' ].

        dictionaryOop := session
          returnRemoteCommandBody: '| dictionary |
dictionary := Dictionary new.
1 to: size do: [ :index | dictionary at: index put: index + size ].
dictionary'
          literalBindings: (Dictionary new
            at: 'size' put: dictionarySize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        dictionaryMs := millisecondsToRun value: [
          dictionaryResult := session fetchObject: dictionaryOop ].
        ((dictionaryResult size = dictionarySize)
          and: [ (dictionaryResult at: 1) = (dictionarySize + 1)
          and: [ (dictionaryResult at: dictionarySize) = (dictionarySize * 2) ] ]) ifFalse: [
            Error signal: 'Dictionary materialization produced an unexpected result.' ].

        shallowOop := session
          returnRemoteCommandBody: '| root |
root := Array new: size.
1 to: size do: [ :index | root at: index put: (Array with: index with: index + 1) ].
root'
          literalBindings: (Dictionary new
            at: 'size' put: shallowSize;
            yourself)
          oopBindings: Dictionary new.

        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchShallow.
        shallowMs := millisecondsToRun value: [
          shallowResult := session fetchObject: shallowOop ].
        ((shallowResult size = shallowSize)
          and: [ (shallowResult first isKindOf: proxyClass)
          and: [ shallowResult last oop notNil ] ]) ifFalse: [
            Error signal: 'Shallow materialization produced an unexpected result.' ].

        Transcript
          show: 'MATERIALIZATION_PERF_BASELINE result=OK code=MATERIALIZATION_PERF_OK',
            ' array_ms=', arrayMs asString,
            ' dictionary_ms=', dictionaryMs asString,
            ' shallow_ms=', shallowMs asString,
            ' array_size=', arraySize asString,
            ' dictionary_size=', dictionarySize asString,
            ' shallow_size=', shallowSize asString;
          cr.
      ] ensure: [
        [ session abortTransaction ] on: Error do: [ ].
        [ supportClass releaseOwnedSession ] on: Error do: [ ] ]
    ] on: Error do: [ :ex |
      Transcript
        show: 'MATERIALIZATION_PERF_BASELINE result=FAIL code=MATERIALIZATION_PERF_RUN_FAILED array_ms=0 dictionary_ms=0 shallow_ms=0 array_size=0 dictionary_size=0 shallow_size=0 message=';
        show: (ex messageText ifNil: [ ex printString ]) withBlanksTrimmed;
        cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
