Extension { #name : 'Association' }

{ #category : '*GemStone-GBS-Core' }
Association >> key: anObject [
	key := anObject.
	self gbsConsiderModified.
	^ anObject
]

{ #category : '*GemStone-GBS-Core' }
Association >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
Association >> key: keyObject value: valueObject [
	key := keyObject.
	value := valueObject.
	self gbsConsiderModified.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Association >> value: anObject [
	value := anObject.
	self gbsConsiderModified.
	^ anObject
]
