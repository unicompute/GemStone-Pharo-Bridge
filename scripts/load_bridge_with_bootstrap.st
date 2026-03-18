[
	| loadTonelFiles |

	loadTonelFiles := [ :packageName :fileNames |
		| reader |
		reader := TonelReader
			on: '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src' asFileReference
			fileName: packageName.
		fileNames do: [ :fileName |
			(reader parseTonelFile: (reader packageDirectory / fileName))
				do: [ :definition | definition load ] ] ].

	#(
		BaselineOfGemStonePharo
		FourByteString
		GbsMessageNotUnderstood
		GbsZeroDivide
		GbxAbstractContextEmergencyError
		GbxAbstractControlInterrupt
		GbxAbstractException
		GbxAbstractProxy
		CannotReturn
		GbsServerInterface
		GbsSession
		GbsClassicLauncher
		GbsLauncher
		GbsSessionParametersEditor
		GbsWorkspace
		GbsRemoteTranscript
		GbsX509ParametersEditor
		LargeGrainMemoryPolicy
		Subsystem
		TwoByteString
		Unicode16
		Unicode32
		GbxServerInterface
	) do: [ :className |
		(Smalltalk at: className ifAbsent: [ nil ]) ifNotNil: [ :existing |
			[ existing removeFromSystem ] on: Error do: [ ] ] ].

	[ loadTonelFiles
		value: 'BaselineOfGemStonePharo'
		value: #('BaselineOfGemStonePharo.class.st') ]
		on: Error
		do: [ :ex |
			Transcript show: 'BASELINE_BOOTSTRAP_ERROR: ', ex messageText; cr.
			^ Smalltalk snapshot: false andQuit: true
		].

	[ '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/prebootstrap_pharo13.st' asFileReference fileIn ]
		on: Error
		do: [ :ex |
			Transcript show: 'COMPAT_BOOTSTRAP_ERROR: ', ex messageText; cr.
			^ Smalltalk snapshot: false andQuit: true
		].

	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'Tools' ]
		on: Error
		do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			^ Smalltalk snapshot: false andQuit: true
		].

	Transcript show: 'LOAD_OK'; cr.
] on: Error do: [ :ex |
	Transcript show: 'UNEXPECTED_ERROR: ', ex messageText; cr
].

Smalltalk snapshot: false andQuit: true
