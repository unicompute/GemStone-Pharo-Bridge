| logLine runnerClass tonelRepository result |

logLine := [ :line |
	Transcript show: line; cr ].

runnerClass := Smalltalk at: #GemStonePharoVerificationRunner ifAbsent: [ nil ].
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
	runnerClass := Smalltalk at: #GemStonePharoVerificationRunner ifAbsent: [ nil ] ].

runnerClass
	ifNil: [
		logLine value: 'LIVE_PREFLIGHT_FAILED missing GemStonePharoVerificationRunner'.
		logLine value: 'LIVE_PREFLIGHT_SUMMARY result=FAIL code=LIVE_PREFLIGHT_RUNNER_FAILED stone=gs64stone service=gemnetobject host=implicit net=implicit stone_status=unknown netldi_status=unknown topaz=failed gci=failed' ]
	ifNotNil: [
		[ result := runnerClass
			runPreflightOnEnvironment: Smalltalk os environment
			log: logLine
			imagePath: Smalltalk image imageFile asString ]
			on: Error
			do: [ :ex |
				logLine value: 'LIVE_PREFLIGHT_FAILED: ', ex messageText.
				logLine value: 'LIVE_PREFLIGHT_SUMMARY result=FAIL code=LIVE_PREFLIGHT_RUNNER_FAILED stone=gs64stone service=gemnetobject host=implicit net=implicit stone_status=unknown netldi_status=unknown topaz=failed gci=failed'.
				result := { #failed. 'LIVE_PREFLIGHT_RUNNER_FAILED' } ] ].

Smalltalk snapshot: false andQuit: true.
