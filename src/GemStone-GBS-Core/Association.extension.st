Extension { #name : 'Association' }

{ #category : '*GemStone-GBS-Core' }
Association >> key: anObject [
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: 1 noModError: nil ].
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
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: nil noModError: nil ].
	key := keyObject.
	value := valueObject.
	self gbxConsiderModified.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Association >> value: anObject [
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: 2 noModError: nil ].
	value := anObject.
	self gbxConsiderModified.
	^ anObject
]
