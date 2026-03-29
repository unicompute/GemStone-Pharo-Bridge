| suite result testClasses failures errors skipped |
[
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  testClasses := (Smalltalk allClasses
    select: [ :each |
      (each inheritsFrom: TestCase)
        and: [ each package name = 'GemStone-Pharo-Tests' ] ])
    asSortedCollection: [ :a :b | a name <= b name ].

  suite := OrderedCollection new.
  testClasses do: [ :each | suite addAll: each suite tests ].

  result := TestResult new.
  suite do: [ :testCase | testCase run: result ].

  failures := result failures size.
  errors := result errors size.
  skipped := (result respondsTo: #skippedCount)
    ifTrue: [ result skippedCount ]
    ifFalse: [ 0 ].
  Transcript
    show: 'BRIDGE_REGRESSION CLASSES=' , testClasses size asString,
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
] ensure: [ Smalltalk snapshot: false andQuit: true ].
