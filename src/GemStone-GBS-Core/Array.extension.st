Extension { #name : 'Array' }

{ #category : '*GemStone-GBS-Core' }
Array >> at: index put: value [
	| result |
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: index noModError: nil ].
	result := self basicAt: index put: value.
	self gbxConsiderModified.
	^ result
]

{ #category : '*GemStone-GBS-Core' }
Array >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]
