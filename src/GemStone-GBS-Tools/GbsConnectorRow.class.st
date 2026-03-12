Class {
	#name : 'GbsConnectorRow',
	#superclass : 'Object',
	#instVars : [
		'type',
		'clientName',
		'serverName'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsConnectorRow class >> type: aType client: aClient server: aServer [
	^ self new
		type: aType;
		clientName: aClient;
		serverName: aServer;
		yourself
]

{ #category : 'accessing' }
GbsConnectorRow >> type [
	^ type ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorRow >> type: aString [
	type := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorRow >> clientName [
	^ clientName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorRow >> clientName: aString [
	clientName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsConnectorRow >> serverName [
	^ serverName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsConnectorRow >> serverName: aString [
	serverName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'printing' }
GbsConnectorRow >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self clientName;
		nextPutAll: ' -> ';
		nextPutAll: self serverName;
		nextPut: $)
]
