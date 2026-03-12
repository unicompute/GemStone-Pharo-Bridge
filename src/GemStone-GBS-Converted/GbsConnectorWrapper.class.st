Class {
	#name : 'GbsConnectorWrapper',
	#superclass : 'Object',
	#instVars : [
		'connector',
		'clientName',
		'serverName',
		'postConnectAction',
		'invalidPostConnectActions',
		'connectionStateBySession'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsConnectorWrapper class >> client: aClientName server: aServerName [
	^ self new
		clientName: aClientName;
		serverName: aServerName;
		yourself
]

{ #category : 'instance creation' }
GbsConnectorWrapper class >> connector: aGbsConnector [
	^ self new
		connector: aGbsConnector;
		yourself
]

{ #category : 'initialization' }
GbsConnectorWrapper >> initialize [
	super initialize.
	postConnectAction := 'none'.
	invalidPostConnectActions := #().
	connectionStateBySession := Dictionary new
]

{ #category : 'accessing' }
GbsConnectorWrapper >> connector [
	^ connector
]

{ #category : 'accessing' }
GbsConnectorWrapper >> connector: aGbsConnector [
	connector := aGbsConnector.
	(connector notNil and: [ connector respondsTo: #stDescription ]) ifTrue: [
		self clientName: connector stDescription ].
	(connector notNil and: [ connector respondsTo: #gsDescription ]) ifTrue: [
		self serverName: connector gsDescription ].
]

{ #category : 'accessing' }
GbsConnectorWrapper >> clientName [
	(connector notNil and: [ connector respondsTo: #stDescription ]) ifTrue: [
		^ connector stDescription asString ].
	^ clientName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> clientName: aString [
	clientName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> serverName [
	(connector notNil and: [ connector respondsTo: #gsDescription ]) ifTrue: [
		^ connector gsDescription asString ].
	^ serverName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> connectorClient [
	^ self clientName
]

{ #category : 'accessing' }
GbsConnectorWrapper >> connectorServer [
	^ self serverName
]

{ #category : 'accessing' }
GbsConnectorWrapper >> connectorType [
	(connector notNil and: [ connector class respondsTo: #type ]) ifTrue: [
		^ connector class type ].
	^ 'Connector'
]

{ #category : 'accessing' }
GbsConnectorWrapper >> serverName: aString [
	serverName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> postConnectAction [
	(connector notNil and: [ connector respondsTo: #postConnectAction ]) ifTrue: [
		^ connector postConnectAction ].
	^ postConnectAction ifNil: [ 'none' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> postConnectAction: anActionString [
	(connector notNil and: [ connector respondsTo: #postConnectAction: ]) ifTrue: [
		^ connector postConnectAction: anActionString ].
	postConnectAction := anActionString ifNil: [ 'none' ] ifNotNil: [ anActionString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> invalidPostConnectActions [
	(connector notNil and: [ connector respondsTo: #invalidPostConnectActions ]) ifTrue: [
		^ connector invalidPostConnectActions ].
	^ invalidPostConnectActions ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> invalidPostConnectActions: aCollection [
	(connector notNil and: [ connector respondsTo: #invalidPostConnectActions: ]) ifTrue: [
		^ connector invalidPostConnectActions: aCollection ].
	invalidPostConnectActions := ((aCollection ifNil: [ #() ]) collect: [ :each | each asString asLowercase ]) asArray
]

{ #category : 'actions' }
GbsConnectorWrapper >> connectInSession: aSession ifFail: oneArgBlock [
	(connector notNil and: [ connector respondsTo: #connectInSession:ifFail: ]) ifTrue: [
		^ connector connectInSession: aSession ifFail: oneArgBlock ].
	| key |
	key := self sessionKeyFor: aSession.
	connectionStateBySession at: key put: true.
	^ true
]

{ #category : 'actions' }
GbsConnectorWrapper >> disconnectInSession: aSession [
	(connector notNil and: [ connector respondsTo: #disconnectInSession: ]) ifTrue: [
		^ connector disconnectInSession: aSession ].
	| key |
	key := self sessionKeyFor: aSession.
	connectionStateBySession at: key put: false.
	^ true
]

{ #category : 'testing' }
GbsConnectorWrapper >> isConnectedInSession: aSession [
	(connector notNil and: [ connector respondsTo: #isConnectedInSession: ]) ifTrue: [
		^ connector isConnectedInSession: aSession ].
	| key |
	key := self sessionKeyFor: aSession.
	^ connectionStateBySession at: key ifAbsent: [ true ]
]

{ #category : 'testing' }
GbsConnectorWrapper >> isConnectedForSessionKey: sessionKey [
	(connector notNil and: [ connector respondsTo: #isConnectedForSessionKey: ]) ifTrue: [
		^ connector isConnectedForSessionKey: sessionKey ].
	| key |
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	^ connectionStateBySession at: key ifAbsent: [ true ]
]

{ #category : 'actions' }
GbsConnectorWrapper >> setConnected: aBoolean forSessionKey: sessionKey [
	(connector notNil and: [ connector respondsTo: #setConnected:forSessionKey: ]) ifTrue: [
		^ connector setConnected: aBoolean forSessionKey: sessionKey ].
	| key |
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	connectionStateBySession at: key put: (aBoolean == true).
	^ aBoolean == true
]

{ #category : 'testing' }
GbsConnectorWrapper >> connectsAssociation [
	(connector notNil and: [ connector respondsTo: #connectsAssociation ]) ifTrue: [
		^ connector connectsAssociation ].
	^ false
]

{ #category : 'resolving' }
GbsConnectorWrapper >> resolveSTObjIfFail: failBlock [
	(connector notNil and: [ connector respondsTo: #resolveSTObjIfFail: ]) ifTrue: [
		^ connector resolveSTObjIfFail: failBlock ].
	^ failBlock value
]

{ #category : 'resolving' }
GbsConnectorWrapper >> resolveGSObjInSession: aSession ifFail: failBlock [
	(connector notNil and: [ connector respondsTo: #resolveGSObjInSession:ifFail: ]) ifTrue: [
		^ connector resolveGSObjInSession: aSession ifFail: failBlock ].
	^ failBlock value
]

{ #category : 'printing' }
GbsConnectorWrapper >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: (connector ifNil: [ self clientName, ' -> ', self serverName ] ifNotNil: [ connector printString ]);
		nextPutAll: ')'
]

{ #category : 'private' }
GbsConnectorWrapper >> sessionKeyFor: aSession [
	| params user stone |
	aSession ifNil: [ ^ 'default' ].
	(aSession respondsTo: #parameters) ifFalse: [ ^ 'default' ].
	params := [ aSession parameters ] on: Error do: [ nil ].
	params ifNil: [ ^ 'default' ].
	user := [ params username ] on: Error do: [ nil ].
	stone := [ params gemStoneName ] on: Error do: [ nil ].
	^ (user ifNil: [ 'unknown-user' ] ifNotNil: [ user asString ]),
		'@',
		(stone ifNil: [ 'unknown-stone' ] ifNotNil: [ stone asString ])
]
