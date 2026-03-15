Class {
	#name : 'GbxConnectorWrapper',
	#superclass : 'GbxDelegate',
	#instVars : [
		'connectorClient',
		'connectorType',
		'connectorServer',
		'connector',
		'session'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxConnectorWrapper class >> client: client type: type server: server connector: conn [
	^ self new
		connectorClient: client;
		connectorType: type;
		connectorServer: server;
		connector: conn;
		yourself
]

{ #category : 'instance creation' }
GbxConnectorWrapper class >> on: aConnector [
	"Create a wrapper for a GemStone connector"
	^ self new
		connector: aConnector;
		yourself
]

{ #category : 'comparing' }
GbxConnectorWrapper >> = anObject [
	^ (anObject isKindOf: GbxConnectorWrapper)
		and: [ connector = anObject connector ]
]

{ #category : 'accessing' }
GbxConnectorWrapper >> asString [
	^ connectorType ifNil: [ '<unknown connector>' ]
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connector [
	^ connector
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connector: aConnector [
	connector := aConnector
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorClient [
	^ connectorClient
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorClient: anObject [
	connectorClient := anObject
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorServer [
	^ connectorServer
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorServer: anObject [
	connectorServer := anObject
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorType [
	^ connectorType
]

{ #category : 'accessing' }
GbxConnectorWrapper >> connectorType: aString [
	connectorType := aString
]

{ #category : 'accessing' }
GbxConnectorWrapper >> hash [
	^ connector ifNotNil: [ connector hash ] ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxConnectorWrapper >> inspectClient [
	"Inspect the client-side object"
	connectorClient ifNotNil: [
		connectorClient inspect.
	].
]

{ #category : 'accessing' }
GbxConnectorWrapper >> inspectServer [
	"Inspect the server-side object"
	connectorServer ifNotNil: [
		session ifNotNil: [
			| oop |
			oop := session serverInterface apiReflectionOopOf: connectorServer.
			oop ifNotNil: [
				GbsInspector inspect: oop session: session.
			].
		].
	].
]

{ #category : 'accessing' }
GbxConnectorWrapper >> printString [
	^ connectorType ifNil: [ 
		connector ifNotNil: [ connector printString ] ifNil: [ '<unknown connector>' ]
	]
]

{ #category : 'accessing' }
GbxConnectorWrapper >> session [
	^ session
]

{ #category : 'accessing' }
GbxConnectorWrapper >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxConnectorWrapper >> synchronize [
	"Synchronize client and server objects"
	connector ifNotNil: [
		connector synchronize.
	].
]
