| runnerClass |
[
  | logLine |
  logLine := [ :line | Transcript show: line; cr ].
  runnerClass := Smalltalk at: #GemStonePharoLaneRunner ifAbsent: [ nil ].
  runnerClass
    ifNil: [ logLine value: 'BRIDGE_REGRESSION_FAILED' ]
    ifNotNil: [
      runnerClass
        runLoadingBaselineAndRegressionOnEnvironment: Smalltalk os environment
        log: logLine ].
] ensure: [
  Smalltalk snapshot: false andQuit: true ].
