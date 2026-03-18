Class {
	#name : 'GbsAdminSessionSupport',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbsAdminSessionSupport class >> currentUsableSession [
	| session |
	session := GbsSessionParameters currentSession.
	session ifNil: [ ^ nil ].
	(self isUsableSession: session) ifTrue: [ ^ session ].
	session := self resolveLiveSessionFrom: session.
	session ifNil: [ ^ nil ].
	GbsSessionParameters currentSession: session.
	^ session
]

{ #category : 'accessing' }
GbsAdminSessionSupport class >> currentUsableSessionOrInform [
	| session |
	session := self currentUsableSession.
	session ifNil: [
		UIManager default inform: 'No connected GemStone session. Please login first.' ].
	^ session
]

{ #category : 'private' }
GbsAdminSessionSupport class >> isUsableSession: session [
	session ifNil: [ ^ false ].
	((session respondsTo: #execute:) or: [ session respondsTo: #executeAndFetch: ])
		ifFalse: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	(session respondsTo: #isConnected)
		ifTrue: [ ^ [ session isConnected == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'private' }
GbsAdminSessionSupport class >> resolveLiveSessionFrom: anObject [
	| sessionId resolved |
	sessionId := self sessionIdFrom: anObject.
	sessionId ifNil: [ ^ nil ].
	resolved := [ GBSM sessionWithId: sessionId ] on: Error do: [ nil ].
	(self isUsableSession: resolved) ifTrue: [ ^ resolved ].
	^ nil
]

{ #category : 'private' }
GbsAdminSessionSupport class >> sessionIdFrom: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #sessionId)
		ifTrue: [ ^ [ anObject sessionId ] on: Error do: [ nil ] ].
	^ nil
]
