Class {
	#name : 'GbxReplicationResolveClientMapProbe',
	#superclass : 'Object',
	#instVars : [
		'session',
		'writeEntered',
		'writeEnteredWhileSessionCritical'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxReplicationResolveClientMapProbe >> session: anObject [
	session := anObject
]

{ #category : 'accessing' }
GbxReplicationResolveClientMapProbe >> writeEntered [
	^ writeEntered = true
]

{ #category : 'accessing' }
GbxReplicationResolveClientMapProbe >> writeEnteredWhileSessionCritical [
	^ writeEnteredWhileSessionCritical = true
]

{ #category : 'accessing' }
GbxReplicationResolveClientMapProbe >> writeCritical: aBlock [
	writeEntered := true.
	writeEnteredWhileSessionCritical := session hasCriticalAccess.
	^ aBlock value
]
