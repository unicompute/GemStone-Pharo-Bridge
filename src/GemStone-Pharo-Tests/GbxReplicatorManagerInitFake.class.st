Class {
	#name : 'GbxReplicatorManagerInitFake',
	#superclass : 'Object',
	#instVars : [
		'queuedReplicators',
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxReplicatorManagerInitFake >> initialize [
	super initialize.
	queuedReplicators := OrderedCollection new
]

{ #category : 'accessing' }
GbxReplicatorManagerInitFake >> queuedReplicators [
	^ queuedReplicators
]

{ #category : 'accessing' }
GbxReplicatorManagerInitFake >> session [
	^ session
]

{ #category : 'accessing' }
GbxReplicatorManagerInitFake >> session: anObject [
	session := anObject
]

{ #category : 'recording' }
GbxReplicatorManagerInitFake >> serverInstVarNamesNeededByReplicator: aReplicator [
	queuedReplicators add: aReplicator
]
