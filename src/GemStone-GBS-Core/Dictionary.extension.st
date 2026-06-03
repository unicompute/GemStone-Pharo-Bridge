Extension { #name : 'Dictionary' }

{ #category : '*GemStone-GBS-Core' }
Dictionary >> gbxDelegate [
	^ GbsMaterializedObjectDirtyTracker delegateForObject: self
]

{ #category : '*GemStone-GBS-Core' }
Dictionary >> at: key put: anObject [
	| index assoc |
	index := self findElementOrNil: key.
	assoc := array at: index.
	assoc
		ifNil: [ self atNewIndex: index put: (Association key: key value: anObject) ]
		ifNotNil: [ assoc value: anObject ].
	self gbxConsiderModified.
	^ anObject
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
