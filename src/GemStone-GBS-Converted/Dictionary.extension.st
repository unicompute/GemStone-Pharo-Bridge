Extension { #name : 'Dictionary' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary class >> gbsReplicatorClass [
	^ GbxDictionaryReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary class >> gbxIndexableSizeFromReport: report [
	^ ((report idxSize max: 3) * 1.3) truncated
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary class >> gsObjImpl [
	^ 0
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary class >> replicationSpec [
	^ super replicationSpec , #(#(#indexable_part #min 1))
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary class >> newFromGSObjectReport: report [
	^ self new: (self gbxIndexableSizeFromReport: report)
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary >> indexableValueAt: index put: aValue [
	aValue isNil ifFalse: [ self add: aValue ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Dictionary >> gbxElementsDo: aBlock [
	^ self associationsDo: aBlock
]
