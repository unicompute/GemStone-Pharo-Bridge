Class {
	#name : 'GbxReplicator',
	#superclass : 'Object',
	#instVars : [
		'target',
		'manager',
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxReplicator >> manager [
	^ manager
]

{ #category : 'accessing' }
GbxReplicator >> manager: anObject [
	manager := anObject
]

{ #category : 'accessing' }
GbxReplicator >> session [
	^ session
]

{ #category : 'accessing' }
GbxReplicator >> session: anObject [
	session := anObject
]

{ #category : 'accessing' }
GbxReplicator >> target [
	^ target
]

{ #category : 'accessing' }
GbxReplicator >> target: anObject [
	target := anObject
]
