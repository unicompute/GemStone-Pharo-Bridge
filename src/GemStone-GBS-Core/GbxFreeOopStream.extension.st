Extension { #name : 'GbxFreeOopStream' }

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream class >> for: aSession [
	^ self new
		initializeForSession: aSession;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream >> batchSize [
	| policy |
	policy := [ GbsReplicationPolicy forSession: session ] on: Error do: [ nil ].
	(policy notNil and: [ policy respondsTo: #freeOopAllocationBatchSize ]) ifTrue: [
		^ policy freeOopAllocationBatchSize max: 1 ].
	^ 2000
]

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream >> initializeForSession: aSession [
	session := aSession.
	cache := #().
	position := 1.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream >> nextFreeOop [
	| oop |
	position > cache size ifTrue: [ self refill ].
	oop := cache at: position.
	cache at: position put: nil.
	position := position + 1.
	oop ifNil: [
		self error: 'No free OOP was available for dirty-store traversal.' ].
	^ oop
]

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream >> refill [
	cache := (session getFreeOops: self batchSize) asArray copy.
	cache isEmpty ifTrue: [
		self error: 'GemStone did not allocate any free OOPs.' ].
	position := 1.
	^ cache
]

{ #category : '*GemStone-GBS-Core' }
GbxFreeOopStream >> session [
	^ session
]
