[
	| baseline repoRoot writeArtifact |
	(Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ]) ifNotNil: [ :organizer |
		[ (organizer default packageNamed: 'BaselineOfGemStonePharo') ifNotNil: [ :package | package removeFromSystem ] ]
			on: Error
			do: [ ] ].
	(Smalltalk at: #BaselineOfGemStonePharo ifAbsent: [ nil ]) ifNotNil: [ :baselineClass |
		[ baselineClass removeFromSystem ]
			on: Error
			do: [ ] ].

	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ]
		on: Error
		do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			self error: ex messageText ].

	baseline := BaselineOfGemStonePharo new.
	repoRoot := '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge' asFileReference.
	writeArtifact := [ :relativePath :contents |
		| file normalized |
		file := repoRoot / relativePath.
		file parent ensureCreateDirectory.
		normalized := (contents ifNil: [ '' ])
			copyReplaceAll: (String with: Character cr)
			with: (String with: Character lf).
		file writeStreamDo: [ :stream | stream nextPutAll: normalized ] ].

	baseline generatedContractArtifactSpecs do: [ :spec |
		writeArtifact value: spec first value: spec second ].

	Transcript show: 'GENERATED_CONTRACT_ARTIFACTS_OK'; cr
] ensure: [ Smalltalk snapshot: false andQuit: true ].
