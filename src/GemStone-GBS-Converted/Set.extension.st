Extension { #name : 'Set' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> goodSizeFrom: requestedSize [
	| size |
	size := requestedSize max: 3.
	size even ifTrue: [ size := size + 1 ].
	[ self gbxIsPrime: size ] whileFalse: [ size := size + 2 ].
	^ size
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> gbxIsPrime: anInteger [
	| limit factor |
	anInteger = 2 ifTrue: [ ^ true ].
	(anInteger < 2 or: [ anInteger even ]) ifTrue: [ ^ false ].
	limit := anInteger sqrt truncated.
	factor := 3.
	[ factor <= limit ] whileTrue: [
		(anInteger \\ factor) = 0 ifTrue: [ ^ false ].
		factor := factor + 2 ].
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> gbsReplicatorClass [
	^ GbxUnorderedCollectionReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> gsObjImpl [
	^ 2
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> replicationSpec [
	^ super replicationSpec , #((indexable_part min 1))
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> newFromGSObjectReport: report [
	^ self new: (self gbxIndexableSizeFromReport: report)
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set class >> gbxIndexableSizeFromReport: report [
	^ ((report idxSize max: 3) * 1.3) truncated
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set >> gbxElementsDo: aBlock [
	^ self do: aBlock
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set >> postFault [
	self markNotDirty
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Set >> indexableValueAt: index put: aValue [
	self add: aValue
]
