Class {
	#name : 'GbsConnectorWrapper',
	#superclass : 'Object',
	#instVars : [
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

{ #category : 'initialization' }
GbsConnectorWrapper >> initialize [
	super initialize.
	postConnectAction := 'none'.
	invalidPostConnectActions := #().
	connectionStateBySession := Dictionary new
]

{ #category : 'accessing' }
GbsConnectorWrapper >> clientName [
	^ clientName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> clientName: aString [
	clientName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> serverName [
	^ serverName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> serverName: aString [
	serverName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> postConnectAction [
	^ postConnectAction ifNil: [ 'none' ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> postConnectAction: anActionString [
	postConnectAction := anActionString ifNil: [ 'none' ] ifNotNil: [ anActionString asString ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> invalidPostConnectActions [
	^ invalidPostConnectActions ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsConnectorWrapper >> invalidPostConnectActions: aCollection [
	invalidPostConnectActions := ((aCollection ifNil: [ #() ]) collect: [ :each | each asString asLowercase ]) asArray
]

{ #category : 'actions' }
GbsConnectorWrapper >> connectInSession: aSession ifFail: oneArgBlock [
	| key |
	key := self sessionKeyFor: aSession.
	connectionStateBySession at: key put: true.
	^ true
]

{ #category : 'actions' }
GbsConnectorWrapper >> disconnectInSession: aSession [
	| key |
	key := self sessionKeyFor: aSession.
	connectionStateBySession at: key put: false.
	^ true
]

{ #category : 'testing' }
GbsConnectorWrapper >> isConnectedInSession: aSession [
	| key |
	key := self sessionKeyFor: aSession.
	^ connectionStateBySession at: key ifAbsent: [ true ]
]

{ #category : 'testing' }
GbsConnectorWrapper >> isConnectedForSessionKey: sessionKey [
	| key |
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	^ connectionStateBySession at: key ifAbsent: [ true ]
]

{ #category : 'actions' }
GbsConnectorWrapper >> setConnected: aBoolean forSessionKey: sessionKey [
	| key |
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	connectionStateBySession at: key put: (aBoolean == true).
	^ aBoolean == true
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
