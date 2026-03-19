Extension { #name : 'Symbol' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol class >> gbsReplicatorClass [
	^ GbxSymbolReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol class >> instancesAreUnique [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol class >> newFromGSObjectReport: report [
	| string |
	string := String newFromGSObjectReport: report.
	string gbxCopyBytesFromReport: report.
	^ self intern: string
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxCanTraversalSplit [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxCouldBeForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxDeepCopyCycles: cycles [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxIsImmutable: bool [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> gbxUpdateFromDelegate: aGSObject [
	self gbsMessenger failure: 'Attempted to update a symbol from GemStone.'
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> markDirty [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> newGSObjectMappingInSession: session [
	| replicate stream |
	stream := WriteStream on: (String new: self size + 3).
	stream
		nextPut: $#;
		nextPut: $'.
	self do: [ :each |
		(stream nextPut: each) = $' ifTrue: [ stream nextPut: $' ] ].
	stream nextPut: $'.
	replicate := session unsynchronizedEvaluate: stream contents.
	replicate == self
		ifFalse: [
			^ self gbsMessenger
				error: 'A non-canonical symbol, %1, was created'
				withArguments: replicate ].
	^ self gbxDelegate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> stubYourself [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Symbol >> toolListDisplayString [
	^ self
]
