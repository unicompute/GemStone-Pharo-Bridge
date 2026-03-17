Class {
	#name : 'GbxNoServerClassReplicator',
	#superclass : 'GbxReplicator',
	#instVars : [
		'clientClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxNoServerClassReplicator >> clientClass
[

	^clientClass
]

{ #category : 'printing' }
GbxNoServerClassReplicator >> printOn: aStream
[

	| name |
	super printOn: aStream.
	name := [clientClass name] on: Error do: [:ex | ex return: ex printString].
	aStream
		nextPutAll: ' for ';
		nextPutAll: name
]

{ #category : 'initialize-release' }
GbxNoServerClassReplicator >> initializeForClientClass: aClientClass manager: aManager
[

	clientClass := aClientClass.
	manager := aManager.
	session := aManager session
]

{ #category : 'instance creation' }
GbxNoServerClassReplicator class >> forClientClass: clientClass manager: manager
[

	^self new initializeForClientClass: clientClass manager: manager
]

{ #category : 'instance creation' }
GbxNoServerClassReplicator class >> forClientClass: clientClass serverClass: delegate manager: manager
[
	"Null replicators don't care what the server class is."

	^self forClientClass: clientClass manager: manager
]

