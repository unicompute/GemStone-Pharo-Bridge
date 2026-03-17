[
	#(
		CannotReturn
		GbsServerInterface
		GbsSession
		GbsClassicLauncher
		GbsLauncher
		GbsSessionParametersEditor
		GbsWorkspace
		GbsRemoteTranscript
		GbsX509ParametersEditor
		GbxServerInterface
	) do: [ :className |
		(Smalltalk at: className ifAbsent: [ nil ]) ifNotNil: [ :existing |
			[ existing removeFromSystem ] on: Error do: [ ] ] ].

	[ '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/prebootstrap_pharo13.st' asFileReference fileIn ]
		on: Error
		do: [ :ex |
			Transcript show: 'PREBOOTSTRAP_ERROR: ', ex messageText; cr.
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
