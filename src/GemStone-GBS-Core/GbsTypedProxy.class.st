Class {
	#name : 'GbsTypedProxy',
	#superclass : 'GbsProxy',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'generated metadata' }
GbsTypedProxy class >> clientBehavior [
	| behaviorName |
	behaviorName := self clientBehaviorName.
	behaviorName isEmpty ifTrue: [ ^ nil ].
	^ Smalltalk globals at: behaviorName asSymbol ifAbsent: [ nil ]
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> clientBehaviorName [
	^ ''
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> lifecycleEntryForSession: aSession [
	^ (GbsSessionManager typedWrapperLifecycleObjectsForSession: aSession)
		detect: [ :each | each wrapperClass == self ]
		ifNone: [ nil ]
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> lifecycleStatusForSession: aSession [
	| entry |
	entry := self lifecycleEntryForSession: aSession.
	^ entry
		ifNil: [ #unknown ]
		ifNotNil: [ entry status ]
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> isLifecycleStaleForSession: aSession [
	^ (self lifecycleStatusForSession: aSession) = #stale
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> generatedForwardingSelectors [
	^ #()
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> generatedForwardingProtocols [
	^ #()
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> generatedForwardingSource [
	^ #client
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> serverBehaviorVersion [
	^ nil
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> serverBehaviorNumberOfVersions [
	^ nil
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> connectorObject [
	^ GbsSessionManager
		connectorObjectForClient: self clientBehaviorName
		server: self serverBehaviorName
]

{ #category : 'generated metadata' }
GbsTypedProxy class >> serverBehaviorName [
	^ ''
]

{ #category : 'generated metadata' }
GbsTypedProxy >> clientBehavior [
	^ self class clientBehavior
]

{ #category : 'generated metadata' }
GbsTypedProxy >> clientBehaviorName [
	^ self class clientBehaviorName
]

{ #category : 'generated metadata' }
GbsTypedProxy >> connectorObject [
	^ self class connectorObject
]

{ #category : 'generated forwarding' }
GbsTypedProxy >> forwardGeneratedRemoteSelector: aSelector arguments: anArray [
	session ifNil: [ self error: 'Typed proxy has no active GemStone session.' ].
	^ session
		forwardRemoteMessage: (Message selector: aSelector arguments: anArray asArray)
		forOop: self oop
]

{ #category : 'testing' }
GbsTypedProxy >> isKindOf: aClass [
	| clientBehavior |
	(super isKindOf: aClass) ifTrue: [ ^ true ].
	(aClass respondsTo: #inheritsFrom:) ifFalse: [ ^ false ].
	clientBehavior := self clientBehavior.
	^ clientBehavior notNil
		and: [ clientBehavior == aClass or: [ clientBehavior inheritsFrom: aClass ] ]
]

{ #category : 'printing' }
GbsTypedProxy >> printOn: aStream [
	aStream
		nextPutAll: 'a';
		nextPutAll: self class name;
		nextPutAll: '(client: ';
		nextPutAll: self clientBehaviorName;
		nextPutAll: ' server: ';
		nextPutAll: self serverBehaviorName;
		nextPutAll: ' oop: '.
	aStream print: self oop.
	aStream nextPut: $)
]

{ #category : 'class membership' }
GbsTypedProxy >> respondsTo: aSymbol [
	| behavior |
	(super respondsTo: aSymbol) ifTrue: [ ^ true ].
	behavior := self clientBehavior.
	^ behavior notNil and: [ behavior canUnderstand: aSymbol ]
]

{ #category : 'generated metadata' }
GbsTypedProxy >> serverBehaviorName [
	^ self class serverBehaviorName
]

{ #category : 'generated metadata' }
GbsTypedProxy >> serverBehaviorNumberOfVersions [
	^ self class serverBehaviorNumberOfVersions
]

{ #category : 'generated metadata' }
GbsTypedProxy >> serverBehaviorVersion [
	^ self class serverBehaviorVersion
]
