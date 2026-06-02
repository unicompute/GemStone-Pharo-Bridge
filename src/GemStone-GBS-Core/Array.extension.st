Extension { #name : 'Array' }

{ #category : '*GemStone-GBS-Core' }
Array >> at: index put: value [
	| result |
	result := self basicAt: index put: value.
	self gbxConsiderModified.
	^ result
]

{ #category : '*GemStone-GBS-Core' }
Array >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]
