[
	| tonelReader criticalFiles |
	tonelReader := Smalltalk at: #TonelReader ifAbsent: [ nil ].
	criticalFiles := #(
		'/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Bootstrap/GbsPharoBootstrap.class.st'
		'/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/CompiledCode.extension.st'
		'/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/CompiledBlock.extension.st'
		'/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/Context.extension.st'
		'/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsStackDumper.class.st'
	).
	tonelReader ifNotNil: [
		criticalFiles do: [ :pathString |
			| file defs |
			file := pathString asFileReference.
			file exists ifTrue: [
				[
					defs := tonelReader new parseTonelFile: file.
					defs do: [ :definition | definition load ]
				] on: Error do: [ :ex |
					Transcript show: 'REPAIR_WARN: ', file basename, ' :: ', ex messageText; cr ] ] ] ].

	(Smalltalk at: #GbsPharoBootstrap ifAbsent: [ nil ])
		ifNil: [
			Transcript show: 'REPAIR_ERROR: GbsPharoBootstrap not present in image'; cr ]
		ifNotNil: [ :bootstrap |
			bootstrap activateCompatibilityInCurrentImage.
			Transcript show: 'REPAIR_OK'; cr ].
] on: Error do: [ :ex |
	Transcript show: 'REPAIR_ERROR: ', ex messageText; cr
].

Smalltalk snapshot: true andQuit: true
