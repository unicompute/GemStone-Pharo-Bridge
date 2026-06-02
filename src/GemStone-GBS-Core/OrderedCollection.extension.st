Extension { #name : 'OrderedCollection' }

{ #category : '*GemStone-GBS-Core' }
OrderedCollection >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

