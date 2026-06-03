Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Core' }
Object >> gbsConsiderModified [
	^ self gbxConsiderModified
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
