Class {
	#name : 'GbxFakeReplicatedObject',
	#superclass : 'Object',
	#instVars : [
		'basicClass',
		'delegate',
		'replicatorClass'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'replication' }
GbxFakeReplicatedObject >> asGSObjectInSession: aSession [
	^ delegate
]

{ #category : 'accessing' }
GbxFakeReplicatedObject >> basicClass: aClass [
	basicClass := aClass
]

{ #category : 'accessing' }
GbxFakeReplicatedObject >> delegate: anObject [
	delegate := anObject
]

{ #category : 'replication' }
GbxFakeReplicatedObject >> gbxBasicClass [
	^ basicClass ifNil: [ self class ]
]

{ #category : 'replication' }
GbxFakeReplicatedObject >> gbxDelegate [
	^ delegate
]

{ #category : 'replication' }
GbxFakeReplicatedObject >> gbxUnmappedClassReplicatorClass [
	^ replicatorClass ifNil: [ GbxFakeUnmappedReplicator ]
]

{ #category : 'accessing' }
GbxFakeReplicatedObject >> replicatorClass: aClass [
	replicatorClass := aClass
]
