Class {
	#name : 'GbsConnectorGroup',
	#superclass : 'Object',
	#instVars : [
		'managerClass',
		'session',
		'isGlobalGroup'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsConnectorGroup class >> globalOnManagerClass: aManagerClass [
	^ self new
		managerClass: aManagerClass;
		isGlobalGroup: true;
		yourself
]

{ #category : 'instance creation' }
GbsConnectorGroup class >> session: aSession managerClass: aManagerClass [
	^ self new
		managerClass: aManagerClass;
		session: aSession;
		isGlobalGroup: false;
		yourself
]

{ #category : 'accessing' }
GbsConnectorGroup >> managerClass: aClass [
	managerClass := aClass
]

{ #category : 'accessing' }
GbsConnectorGroup >> session [
	^ session
]

{ #category : 'accessing' }
GbsConnectorGroup >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsConnectorGroup >> isGlobalGroup [
	^ isGlobalGroup == true
]

{ #category : 'accessing' }
GbsConnectorGroup >> isGlobalGroup: aBoolean [
	isGlobalGroup := aBoolean == true
]

{ #category : 'accessing' }
GbsConnectorGroup >> connectorGroupDescription [
	self isGlobalGroup ifTrue: [ ^ 'Global connectors' ].
	session ifNil: [ ^ 'Session connectors - ''unknown-user'' on ''unknown-stone''' ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Session connectors - ''';
			nextPutAll: (self sessionUsername ifNil: [ 'unknown-user' ]);
			nextPutAll: ''' on ''';
			nextPutAll: (self sessionStoneName ifNil: [ 'unknown-stone' ]);
			nextPutAll: '''' ]
]

{ #category : 'accessing' }
GbsConnectorGroup >> connectorList [
	managerClass ifNil: [ ^ #() ].
	(managerClass respondsTo: #connectorObjects)
		ifTrue: [ ^ managerClass connectorObjects ].
	^ #()
]

{ #category : 'actions' }
GbsConnectorGroup >> addNoConnectConnector: aConnector [
	self addConnector: aConnector
]

{ #category : 'actions' }
GbsConnectorGroup >> addNoConnectGlobalConnector: aConnector [
	self addConnector: aConnector
]

{ #category : 'actions' }
GbsConnectorGroup >> addConnector: aConnector [
	| clientName serverName |
	managerClass ifNil: [ ^ self ].
	clientName := (aConnector respondsTo: #stDescription)
		ifTrue: [ aConnector stDescription ]
		ifFalse: [ '' ].
	serverName := (aConnector respondsTo: #gsDescription)
		ifTrue: [ aConnector gsDescription ]
		ifFalse: [ '' ].
	(managerClass respondsTo: #addConnectorClient:server:)
		ifTrue: [ managerClass addConnectorClient: clientName server: serverName ]
]

{ #category : 'actions' }
GbsConnectorGroup >> removeConnector: aConnector [
	| clientName serverName |
	managerClass ifNil: [ ^ self ].
	clientName := (aConnector respondsTo: #stDescription)
		ifTrue: [ aConnector stDescription ]
		ifFalse: [ '' ].
	serverName := (aConnector respondsTo: #gsDescription)
		ifTrue: [ aConnector gsDescription ]
		ifFalse: [ '' ].
	(managerClass respondsTo: #removeConnectorClient:server:)
		ifTrue: [ managerClass removeConnectorClient: clientName server: serverName ]
]

{ #category : 'actions' }
GbsConnectorGroup >> removeGlobalConnector: aConnector [
	self removeConnector: aConnector
]

{ #category : 'private' }
GbsConnectorGroup >> sessionParameters [
	| params current |
	((session respondsTo: #username) and: [ session respondsTo: #gemStoneName ]) ifTrue: [ ^ session ].
	params := (session respondsTo: #parameters)
		ifTrue: [ [ session parameters ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	params ifNotNil: [ ^ params ].
	current := GbsSessionParameters currentSession.
	((current respondsTo: #username) and: [ current respondsTo: #gemStoneName ]) ifTrue: [ ^ current ].
	(current respondsTo: #parameters) ifFalse: [ ^ nil ].
	^ [ current parameters ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsConnectorGroup >> sessionUsername [
	| params |
	params := self sessionParameters.
	params ifNil: [ ^ nil ].
	^ [ params username asString ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsConnectorGroup >> sessionStoneName [
	| params |
	params := self sessionParameters.
	params ifNil: [ ^ nil ].
	^ [ params gemStoneName asString ] on: Error do: [ nil ]
]

{ #category : 'printing' }
GbsConnectorGroup >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self connectorGroupDescription;
		nextPut: $)
]
