| runnerClass |
[
  | logLine |
  logLine := [ :line | Transcript show: line; cr ].
  runnerClass := Smalltalk at: #GemStonePharoLaneRunner ifAbsent: [ nil ].
  runnerClass
    ifNil: [ logLine value: 'BRIDGE_REGRESSION_FAILED' ]
    ifNotNil: [
      runnerClass
        runLoadingBaselineAndRegressionOnEnvironment: OSEnvironment current
        log: logLine ].
] ensure: [
  Smalltalk snapshot: false andQuit: true ].
