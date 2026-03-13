| reader files testClass suite result |
reader := Smalltalk at: #TonelReader ifAbsent: [ self error: 'TonelReader not found' ].
files := {
  '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsMethodQueryResultsPresenter.class.st'.
  '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsClassicLauncher.class.st'.
  '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/MockGbsSession.class.st'.
  '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbsMethodQueryResultsPresenterTest.class.st'.
}.
files do: [ :path |
  | file defs |
  file := path asFileReference.
  file exists ifTrue: [
    defs := reader new parseTonelFile: file.
    defs do: [ :def | def load ] ] ].

testClass := Smalltalk at: #GbsMethodQueryResultsPresenterTest ifAbsent: [ nil ].
testClass ifNil: [
  Transcript show: 'ERROR: GbsMethodQueryResultsPresenterTest is not loaded'; cr.
  Smalltalk snapshot: false andQuit: true ].

Transcript show: 'Running '; show: testClass name; show: '...'; cr.
suite := testClass buildSuite.
result := suite run.
Transcript
  show: 'RESULT runCount='; show: result runCount asString;
  show: ' failures='; show: result failures size asString;
  show: ' errors='; show: result errors size asString; cr.
result failures do: [ :f | Transcript show: 'FAIL '; show: f printString; cr ].
result errors do: [ :e | Transcript show: 'ERROR '; show: e printString; cr ].

Smalltalk snapshot: false andQuit: true.
