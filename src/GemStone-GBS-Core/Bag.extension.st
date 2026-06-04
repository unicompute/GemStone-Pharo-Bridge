Extension { #name : 'Bag' }

{ #category : '*GemStone-GBS-Core' }
Bag >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
Bag >> add: newObject withOccurrences: anInteger [
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
	contents at: newObject put: (contents at: newObject ifAbsent: [ 0 ]) + anInteger.
	self gbxConsiderModified.
	^ newObject
]

{ #category : '*GemStone-GBS-Core' }
Bag >> remove: oldObject ifAbsent: exceptionBlock [
	| count |
	count := contents at: oldObject ifAbsent: [ ^ exceptionBlock value ].
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
	count = 1
		ifTrue: [ contents removeKey: oldObject ]
		ifFalse: [ contents at: oldObject put: count - 1 ].
	self gbxConsiderModified.
	^ oldObject
]

{ #category : '*GemStone-GBS-Core' }
Bag >> removeKey: oldObject ifAbsent: exceptionBlock [
	contents at: oldObject ifAbsent: [ ^ exceptionBlock value ].
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
	contents removeKey: oldObject.
	self gbxConsiderModified.
	^ oldObject
]
