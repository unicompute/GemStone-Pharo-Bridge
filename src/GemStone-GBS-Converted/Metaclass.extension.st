Extension { #name : 'Metaclass' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Metaclass class >> gbsReplicatorClassInSession: aSession [
	^ aSession replicatorClassForMetaclasses
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Metaclass >> gbxInstanceBehavior [
	^ self soleInstance
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Metaclass >> gbsReplicatorClass [
	^ GbxUnmappedClassReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Metaclass >> gbsReplicatorClassInSession: aSession [
	^ aSession replicatorClassForClasses
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Metaclass >> newGSObjectMappingInSession: sess [
	^ (sess gemStoneClassFor: self soleInstance) remoteClass
]
