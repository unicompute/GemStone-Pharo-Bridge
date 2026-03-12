Class {
	#name : 'GbsConnector',
	#superclass : 'Object',
	#instVars : [
		'postConnectAction',
		'connectionCondition'
	],
	#classInstVars : [
		'type'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialization' }
GbsConnector >> initialize [
	super initialize.
	postConnectAction := 'none'.
	connectionCondition := Dictionary new
]

{ #category : 'accessing' }
GbsConnector >> postConnectAction [
	^ postConnectAction ifNil: [ 'none' ]
]

{ #category : 'accessing' }
GbsConnector >> postConnectAction: anActionString [
	postConnectAction := anActionString ifNil: [ 'none' ] ifNotNil: [ anActionString asString ]
]

{ #category : 'accessing' }
GbsConnector >> invalidPostConnectActions [
	| raw |
	raw := self connectorStateDictionary at: #invalidPostActions ifAbsent: [ #() ].
	(raw isCollection and: [ raw isString not ]) ifFalse: [ ^ #() ].
	^ raw
]

{ #category : 'accessing' }
GbsConnector >> invalidPostConnectActions: aCollection [
	self connectorStateDictionary
		at: #invalidPostActions
		put: (((aCollection ifNil: [ #() ]) collect: [ :each | each asString asLowercase ]) asArray)
]

{ #category : 'actions' }
GbsConnector >> connectInSession: aSession ifFail: oneArgBlock [
	self setConnected: true forSessionKey: (self sessionKeyFor: aSession).
	^ true
]

{ #category : 'actions' }
GbsConnector >> disconnectInSession: aSession [
	self setConnected: false forSessionKey: (self sessionKeyFor: aSession).
	^ true
]

{ #category : 'testing' }
GbsConnector >> isConnectedInSession: aSession [
	^ self isConnectedForSessionKey: (self sessionKeyFor: aSession)
]

{ #category : 'testing' }
GbsConnector >> isConnectedForSessionKey: sessionKey [
	| states key |
	states := self connectorStateDictionary at: #connectedBySession ifAbsentPut: [ Dictionary new ].
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	^ states at: key ifAbsent: [ true ]
]

{ #category : 'actions' }
GbsConnector >> setConnected: aBoolean forSessionKey: sessionKey [
	| states key |
	states := self connectorStateDictionary at: #connectedBySession ifAbsentPut: [ Dictionary new ].
	key := sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ].
	states at: key put: (aBoolean == true).
	^ aBoolean == true
]

{ #category : 'private' }
GbsConnector >> connectorStateDictionary [
	connectionCondition ifNil: [ connectionCondition := Dictionary new ].
	^ connectionCondition
]

{ #category : 'private' }
GbsConnector >> sessionKeyFor: aSession [
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

{ #category : 'accessing' }
GbsConnector >> stDescription [
	^ self connectorClientName
]

{ #category : 'accessing' }
GbsConnector >> gsDescription [
	^ self connectorServerName
]

{ #category : 'accessing' }
GbsConnector >> connectorClientName [
	^ self connectorStateDictionary at: #connectorClientName ifAbsent: [ '' ]
]

{ #category : 'accessing' }
GbsConnector >> connectorClientName: aString [
	self connectorStateDictionary
		at: #connectorClientName
		put: (aString ifNil: [ '' ] ifNotNil: [ aString asString ])
]

{ #category : 'accessing' }
GbsConnector >> connectorServerName [
	^ self connectorStateDictionary at: #connectorServerName ifAbsent: [ '' ]
]

{ #category : 'accessing' }
GbsConnector >> connectorServerName: aString [
	self connectorStateDictionary
		at: #connectorServerName
		put: (aString ifNil: [ '' ] ifNotNil: [ aString asString ])
]

{ #category : 'testing' }
GbsConnector >> connectsAssociation [
	^ false
]

{ #category : 'resolving' }
GbsConnector >> resolveSTObjIfFail: failBlock [
	| clientName obj |
	clientName := self connectorClientName.
	clientName ifNil: [ ^ failBlock value ].
	obj := Smalltalk globals at: clientName asString asSymbol ifAbsent: [ nil ].
	obj ifNil: [ ^ failBlock value ].
	^ obj
]

{ #category : 'resolving' }
GbsConnector >> resolveGSObjInSession: aSession ifFail: failBlock [
	| serverName result |
	aSession ifNil: [ ^ failBlock value ].
	serverName := self connectorServerName.
	(serverName isNil or: [ serverName asString trimBoth isEmpty ]) ifTrue: [ ^ failBlock value ].
	[ result := aSession evaluate: serverName asString ] on: Error do: [ :ex | ^ failBlock value ].
	result ifNil: [ ^ failBlock value ].
	^ result
]
