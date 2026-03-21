Class {
	#name : 'GbsAdminSessionSupport',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbsAdminSessionSupport class >> currentUsableSession [
	| session |
	session := self usableSessionFromCandidate: GbsSessionParameters currentSession.
	session ifNil: [ session := self usableSessionFromRegistry ].
	session ifNil: [
		session := self usableSessionFromCandidate: ([ GBSM searchForCurrentSession ] on: Error do: [ nil ]) ].
	session ifNotNil: [ GbsSessionParameters currentSession: session ].
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

{ #category : 'private' }
GbsAdminSessionSupport class >> usableSessionFromCandidate: anObject [
	anObject ifNil: [ ^ nil ].
	(self isUsableSession: anObject) ifTrue: [ ^ anObject ].
	^ self resolveLiveSessionFrom: anObject
]

{ #category : 'private' }
GbsAdminSessionSupport class >> usableSessionFromRegistry [
	GbsSessionParameters allSessions do: [ :each |
		| session |
		session := self usableSessionFromCandidate: each.
		session ifNotNil: [ ^ session ] ].
	^ nil
]
