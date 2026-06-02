Extension { #name : 'GbxDirtyPool' }

{ #category : '*GemStone-GBS-Core' }
GbxDirtyPool >> clearDirty [
	dirtyAwaitingPacking removeAll.
	^ dirtyAwaitingPacking
]

{ #category : '*GemStone-GBS-Core' }
GbxDirtyPool >> isDirty: anObject [
	^ dirtyAwaitingPacking includes: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbxDirtyPool >> markDirty: anObject [
	dirtyAwaitingPacking add: anObject.
	^ anObject
]

