Extension { #name : 'Set' }

{ #category : '*GemStone-GBS-Core' }
Set >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

