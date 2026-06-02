Extension { #name : 'Association' }

{ #category : '*GemStone-GBS-Core' }
Association >> key: anObject [
	key := anObject.
	self gbxConsiderModified.
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
	self gbxConsiderModified.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Association >> value: anObject [
	value := anObject.
	self gbxConsiderModified.
	^ anObject
]
