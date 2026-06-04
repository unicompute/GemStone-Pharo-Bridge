Extension { #name : 'Set' }

{ #category : '*GemStone-GBS-Core' }
Set >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
Set >> add: newObject [
	| index |
	index := self scanFor: newObject.
	(array at: index)
		ifNil: [
			(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
				self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
			self atNewIndex: index put: newObject asCollectionElement.
			self gbxConsiderModified ].
	^ newObject
]

{ #category : '*GemStone-GBS-Core' }
Set >> remove: oldObject ifAbsent: aBlock [
	| index |
	index := self findElementOrNil: oldObject.
	(array at: index) ifNil: [ ^ aBlock value ].
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
	array at: index put: nil.
	tally := tally - 1.
	self fixCollisionsFrom: index.
	self gbxConsiderModified.
	^ oldObject
]
