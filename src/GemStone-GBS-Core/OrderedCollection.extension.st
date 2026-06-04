Extension { #name : 'OrderedCollection' }

{ #category : '*GemStone-GBS-Core' }
OrderedCollection >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
OrderedCollection >> add: newObject [
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
	self addLast: newObject.
	self gbxConsiderModified.
	^ newObject
]

{ #category : '*GemStone-GBS-Core' }
OrderedCollection >> remove: oldObject ifAbsent: absentBlock [
	| index |
	index := firstIndex.
	[ index <= lastIndex ]
		whileTrue: [
			oldObject = (array at: index)
				ifTrue: [
					(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
						self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
					self removeIndex: index.
					self gbxConsiderModified.
					^ oldObject ]
				ifFalse: [ index := index + 1 ] ].
	^ absentBlock value
]
