Extension { #name : 'OrderedCollection' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
OrderedCollection class >> gbsReplicatorClass [
	^ GbxOrderedCollectionReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
OrderedCollection >> indexableValueAt: index [
	^ self at: index
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
OrderedCollection >> indexableSize [
	^ self size
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
OrderedCollection >> indexableValueAt: index put: aValue [
	[ self size < index ] whileTrue: [ self addLast: nil ].
	self at: index put: aValue
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
OrderedCollection >> postFault [
	self markNotDirty
]
