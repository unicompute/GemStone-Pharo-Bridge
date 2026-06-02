Extension { #name : 'Bag' }

{ #category : '*GemStone-GBS-Core' }
Bag >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

