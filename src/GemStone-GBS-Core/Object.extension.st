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
Object >> fault [
	^ self faultToLevel: nil
]

{ #category : '*GemStone-GBS-Core' }
Object >> faultToLevel: levelOrNil [
	"Compatibility with VisualWorks GBS. Non-proxy materialized objects are
	already faulted; if the receiver is tracked, refresh it through the owning
	session so stale stubs/proxies and fault policies are still honored."
	| session oop |
	session := GbsMaterializedObjectDirtyTracker sessionTrackingObject: self.
	session ifNil: [ ^ self ].
	oop := GbsMaterializedObjectDirtyTracker oopForObject: self inSession: session.
	oop ifNil: [ ^ self ].
	^ GbsSessionLifecycleManager faultObjectForOop: oop inSession: session
]

{ #category : '*GemStone-GBS-Core' }
Object >> freeSlotsOnStubbing [
	^ self class freeSlotsOnStubbing
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsAt: index put: anObject [
	| result |
	result := self at: index put: anObject.
	self gbxConsiderModified.
	^ result
]

{ #category : '*GemStone-GBS-Core' }
Object class >> freeSlotsOnStubbing [
	^ GbsReplicationPolicy default freeSlotsOnStubbing
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsStoreIndexableValues [
	^ self indexableValues
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbsStoreNamedValues [
	^ self namedValues
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbxAt: index put: anObject [
	^ self gbsAt: index put: anObject
]

{ #category : '*GemStone-GBS-Core' }
Object class >> instancesAreForwarders [
	^ false
]

{ #category : '*GemStone-GBS-Core' }
Object >> gbxInstVarAt: slotIndex put: anObject [
	^ self gbsInstVarAt: slotIndex put: anObject
]

{ #category : '*GemStone-GBS-Core' }
Object >> indexableValues [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Object >> indexableValues: anArray [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Object >> indexableValuesBuffer [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Object >> namedValues [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Object >> namedValues: anArray [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
Object >> namedValuesBuffer [
	^ self
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
Object >> stubYourself [
	| session |
	session := GbsMaterializedObjectDirtyTracker sessionTrackingObject: self.
	session ifNil: [ ^ self ].
	^ GbsSessionLifecycleManager stubObject: self inSession: session
]

{ #category : '*GemStone-GBS-Core' }
Object class >> transitiveClosureSpec [
	^ self replicationSpec
]
