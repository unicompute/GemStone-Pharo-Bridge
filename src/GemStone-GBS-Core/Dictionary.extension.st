Extension { #name : 'Dictionary' }

{ #category : '*GemStone-GBS-Core' }
Dictionary >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
Dictionary >> removeKey: key ifAbsent: aBlock [
	| index assoc |
	index := self findElementOrNil: key.
	assoc := array at: index.
	assoc ifNil: [ ^ aBlock value ].
	array at: index put: nil.
	tally := tally - 1.
	self fixCollisionsFrom: index.
	self gbxConsiderModified.
	^ assoc value
]
