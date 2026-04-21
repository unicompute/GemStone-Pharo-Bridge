| logLine runnerClass tonelRepository |

logLine := [ :line |
	Transcript show: line; cr ].

runnerClass := Smalltalk at: #GemStonePharoVerifyRunner ifAbsent: [ nil ].
runnerClass ifNil: [
	tonelRepository := [ MCRepository fromUrl: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src' ]
		on: Error
		do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			nil ].
	tonelRepository ifNotNil: [
		[ (tonelRepository versionFrom: 'BaselineOfGemStonePharo') load ]
			on: Error
			do: [ :ex | Transcript show: 'LOAD_ERROR: ', ex messageText; cr ] ].
	runnerClass := Smalltalk at: #GemStonePharoVerifyRunner ifAbsent: [ nil ] ].

runnerClass
	ifNil: [
		logLine value: 'VERIFY_SUMMARY result=FAIL code=VERIFY_RUNNER_FAILED core_only=failed bootstrap_smoke=skipped full=skipped artifact_freshness=skipped summary_renderer=skipped' ]
	ifNotNil: [
		[ runnerClass runOnEnvironment: Smalltalk os environment log: logLine ]
			on: Error
			do: [ :ex |
				logLine value: 'VERIFY_RUNNER_FAILED: ', ex messageText.
				logLine value: 'VERIFY_SUMMARY result=FAIL code=VERIFY_RUNNER_FAILED core_only=failed bootstrap_smoke=skipped full=skipped artifact_freshness=skipped summary_renderer=skipped' ] ].

Smalltalk snapshot: false andQuit: true.
