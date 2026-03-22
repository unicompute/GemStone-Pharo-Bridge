Class {
	#name : 'GbxReplicationSynchronizationTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxReplicationSynchronizationTest >> testResolveHoldsSessionProtectBeforeCacheWrite [
	| session replication previousGBSM hadPreviousGBSM clientMap manager |
	session := MockGbsSession new.
	session sessionId: 1.
	session instVarNamed: 'sessionProtect' put: GbxSessionRecursionLock forMutualExclusion.
	clientMap := GbxReplicationResolveClientMapProbe new.
	clientMap session: session.
	manager := GbxReplicationResolveManagerProbe new.
	manager clientMap: clientMap.
	hadPreviousGBSM := Smalltalk globals includesKey: #GBSM.
	previousGBSM := Smalltalk at: #GBSM ifAbsent: [ nil ].

	[
		Smalltalk at: #GBSM put: manager.
		replication := GbxReplication new.
		replication session: session.
		replication instVarNamed: 'objectsWithDeferredAssignments' put: OrderedCollection new.
		replication instVarNamed: 'reportsWithNoMappedClass' put: OrderedCollection new.
		replication instVarNamed: 'reportsWithDeferredElements' put: OrderedCollection new.

		replication resolve.

		self assert: clientMap writeEntered.
		self assert: clientMap writeEnteredWhileSessionCritical
	] ensure: [
		hadPreviousGBSM
			ifTrue: [ Smalltalk at: #GBSM put: previousGBSM ]
			ifFalse: [ Smalltalk globals removeKey: #GBSM ifAbsent: [ ] ] ]
]
