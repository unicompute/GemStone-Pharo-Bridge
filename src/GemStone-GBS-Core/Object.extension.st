Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Core' }
Object >> gbsConsiderModified [
	^ self gbxConsiderModified
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsConsiderModifiedAt: slotIndex [
	| session |
	session := GbsMaterializedObjectDirtyTracker sessionTrackingObject: self.
	session ifNil: [ ^ self gbsConsiderModified ].
	^ GbsMaterializedObjectDirtyTracker
		markObject: self
		dirtyAtNamedSlot: slotIndex
		inSession: session
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsBasicAt: index put: anObject [
	| result |
	result := self basicAt: index put: anObject.
	self gbxConsiderModified.
	^ result
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsInstVarAt: slotIndex put: anObject [
	self instVarAt: slotIndex put: anObject.
	self gbsConsiderModifiedAt: slotIndex.
	^ anObject
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbxBasicAt: index put: anObject [
	^ self gbsBasicAt: index put: anObject
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbxConsiderModifiedAt: slotIndex [
	^ self gbsConsiderModifiedAt: slotIndex
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbxMutationAt: slotIndex value: anObject noModError: ignoredError [
	| namedSize indexedIndex |
	slotIndex isInteger ifFalse: [
		self gbxConsiderModified.
		^ anObject ].
	namedSize := [ self class instSize ] on: Error do: [ 0 ].
	slotIndex <= namedSize ifTrue: [
		^ self gbsInstVarAt: slotIndex put: anObject ].
	indexedIndex := slotIndex - namedSize.
	indexedIndex > 0 ifTrue: [
		^ self gbsBasicAt: indexedIndex put: anObject ].
	self gbxConsiderModified.
	^ anObject
]

{ #category : '*GemStone-GBS-Core' }
Object >> faultPolicy [
	| session policy |
	session := GbsMaterializedObjectDirtyTracker sessionTrackingObject: self.
	policy := session
		ifNil: [ GbsReplicationPolicy default ]
		ifNotNil: [ GbsReplicationPolicy forSession: session ].
	^ policy defaultFaultPolicySymbol
]

{ #category : '*GemStone-GBS-Core' }
Object class >> freeSlotsOnStubbing [
	^ GbsReplicationPolicy default freeSlotsOnStubbing
]

{ #category : '*GemStone-GBS-Core' }
Object class >> instancesAreForwarders [
	^ false
]

{ #category : '*GemStone-GBS-Core' }
Object class >> gbsReplicatorClassInSession: aSession [
	^ GbxObjectReplicator
]

{ #category : '*GemStone-GBS-Core' }
Object class >> noStubLevel [
	^ 0
]

{ #category : '*GemStone-GBS-Core' }
Object class >> replicationSpec [
	^ #()
]

{ #category : '*GemStone-GBS-Core' }
Object class >> transitiveClosureSpec [
	^ self replicationSpec
]
