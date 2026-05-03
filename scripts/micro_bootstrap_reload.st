| logLine bootstrapperClass tonelRepository |

logLine := [ :line |
	Transcript show: line; cr ].

bootstrapperClass := Smalltalk at: #GemStonePharoReloadBootstrapper ifAbsent: [ nil ].
bootstrapperClass ifNil: [
	tonelRepository := [ MCRepository fromUrl: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src' ]
		on: Error
		do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			nil ].
	tonelRepository ifNotNil: [
		[ (tonelRepository versionFrom: 'BaselineOfGemStonePharo') load ]
			on: Error
			do: [ :ex | Transcript show: 'LOAD_ERROR: ', ex messageText; cr ] ].
	bootstrapperClass := Smalltalk at: #GemStonePharoReloadBootstrapper ifAbsent: [ nil ] ].

bootstrapperClass
	ifNil: [
		logLine value: 'ARCHITECTURE_BOUNDARY_FAIL missing GemStonePharoReloadBootstrapper after helper package load'.
		logLine value: 'ARCHITECTURE_BOUNDARY_FAILED'.
		logLine value: 'PACKAGE_OWNERSHIP_DRIFT_FAILED'.
		logLine value: 'NO_COMPAT_SOURCE_SCAN_FAILED' ]
	ifNotNil: [
		bootstrapperClass
			runBootstrapReloadOnEnvironment: Smalltalk os environment
			log: logLine ].

Smalltalk snapshot: true andQuit: true.
