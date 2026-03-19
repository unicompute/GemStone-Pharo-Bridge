Extension { #name : 'Bag' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag class >> gbsReplicatorClass [
	^ GbxUnorderedCollectionReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag class >> gbxIndexableSizeFromReport: report [
	^ ((report idxSize max: 3) * 1.3) truncated
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag class >> replicationSpec [
	^ super replicationSpec , #((indexable_part min 1))
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag class >> gsObjImpl [
	^ 2
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag class >> newFromGSObjectReport: report [
	^ self new: (self gbxIndexableSizeFromReport: report)
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag >> indexableValueAt: index put: aValue [
	self add: aValue
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag >> postFault [
	self markNotDirty
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Bag >> indexableValues [
	^ (OrderedCollection new: self size)
		addAll: self;
		yourself
]
