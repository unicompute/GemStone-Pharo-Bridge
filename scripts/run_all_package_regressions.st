| suite result testClasses selectedTests failures errors skipped lane label liveLane hadFailure flattenTest sessionReady |
[
  | loadGroup packageFilter filterTokens |
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: (([ Smalltalk os environment at: 'GBS_LOAD_GROUP' ifAbsent: [ 'default' ] ]
        on: Error do: [ 'default' ]) asString) ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  lane := (([ Smalltalk os environment at: 'GBS_TEST_LANE' ifAbsent: [ 'all' ] ]
    on: Error do: [ 'all' ]) asString) asLowercase.
  liveLane := lane = 'live'.
  sessionReady := true.

  liveLane ifTrue: [
    (GbsLiveSessionTestSupport ensureSharedSession) ifNil: [
      sessionReady := false.
      Transcript show: 'LIVE_SESSION_ERROR: ', GbsLiveSessionTestSupport unavailableReason; cr.
      Transcript show: 'BRIDGE_LIVE_REGRESSION_FAILED'; cr ] ].

  packageFilter := ([ Smalltalk os environment at: 'GBS_TEST_PACKAGES' ifAbsent: [ '' ] ]
    on: Error do: [ '' ]) asString trimBoth.
  filterTokens := packageFilter isEmpty
    ifTrue: [ nil ]
    ifFalse: [ (packageFilter findTokens: ',') collect: #trimBoth thenReject: #isEmpty ].

  testClasses := (Smalltalk allClasses
    select: [ :each |
      (each inheritsFrom: TestCase)
        and: [
          | packageName |
          packageName := each package name.
          filterTokens
            ifNil: [ packageName beginsWith: 'GemStone-Pharo-' ]
            ifNotNil: [ filterTokens includes: packageName ] ] ])
    asSortedCollection: [ :a :b | a name <= b name ].

  suite := OrderedCollection new.
  flattenTest := [ :collection :candidate |
    (candidate isKindOf: TestSuite)
      ifTrue: [ candidate tests do: [ :each | flattenTest value: collection value: each ] ]
      ifFalse: [ collection add: candidate ] ].
  testClasses do: [ :each |
    each suite tests do: [ :candidate |
      flattenTest value: suite value: candidate ] ].

  selectedTests := suite select: [ :testCase |
    | protocol isIntegration |
    protocol := [ (testCase class >> testCase selector) protocol name ]
      on: Error
      do: [ nil ].
    isIntegration := protocol notNil
      and: [ protocol = 'integration tests' ].
    lane = 'unit'
      ifTrue: [ isIntegration not ]
      ifFalse: [
        liveLane
          ifTrue: [ isIntegration ]
          ifFalse: [ true ] ] ].

  result := TestResult new.
  sessionReady ifTrue: [
    selectedTests do: [ :testCase | testCase run: result ] ]
  ifFalse: [ ].

  failures := result failures size.
  errors := result errors size.
  skipped := (result respondsTo: #skippedCount)
    ifTrue: [ result skippedCount ]
    ifFalse: [ 0 ].
  label := lane = 'unit'
    ifTrue: [ 'BRIDGE_UNIT_REGRESSION' ]
    ifFalse: [
      liveLane
        ifTrue: [ 'BRIDGE_LIVE_REGRESSION' ]
        ifFalse: [ 'BRIDGE_REGRESSION' ] ].
  Transcript
    show: label , ' CLASSES=' , ((selectedTests collect: [ :each | each class ]) asSet size asString),
      ' RUN=' , result runCount asString,
      ' FAIL=' , failures asString,
      ' ERR=' , errors asString,
      ' SKIP=' , skipped asString;
    cr.

  failures > 0 ifTrue: [
    Transcript show: 'FAILURES:'; cr.
    result failures do: [ :f | Transcript show: f printString; cr ] ].

  errors > 0 ifTrue: [
    Transcript show: 'ERRORS:'; cr.
    result errors do: [ :e | Transcript show: e printString; cr ] ].
  hadFailure := failures > 0
    or: [ errors > 0
    or: [ liveLane and: [ skipped > 0 or: [ sessionReady not ] ] ] ].
  Transcript show: (hadFailure
    ifTrue: [ label , '_FAILED' ]
    ifFalse: [ label , '_OK' ]); cr.
] ensure: [
  GbsLiveSessionTestSupport releaseOwnedSession.
  Smalltalk snapshot: false andQuit: true ].
