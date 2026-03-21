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
	session ifNil: [ session := self usableSessionFromCandidate: self currentManagerSession ].
	session ifNil: [ session := self usableSessionFromRegistry ].
	session ifNil: [ session := self usableSessionFromCandidate: self searchedManagerCurrentSession ].
	session ifNotNil: [ self publishCurrentSession: session ].
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
GbsAdminSessionSupport class >> currentManagerSession [
	| manager |
	manager := [ GBSM managerIfPresent ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	^ [ manager currentSessionIfNone: [ nil ] ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsAdminSessionSupport class >> liveSessionFromCandidate: anObject [
	| parameters resolved |
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #liveSession)
		ifTrue: [
			resolved := [ anObject liveSession ] on: Error do: [ nil ].
			resolved ifNotNil: [ ^ resolved ] ].
	(anObject respondsTo: #liveSessionFromParameters)
		ifTrue: [
			resolved := [ anObject liveSessionFromParameters ] on: Error do: [ nil ].
			resolved ifNotNil: [ ^ resolved ] ].
	(anObject respondsTo: #parameters) ifFalse: [ ^ nil ].
	parameters := [ anObject parameters ] on: Error do: [ nil ].
	parameters ifNil: [ ^ nil ].
	(parameters respondsTo: #liveSession)
		ifTrue: [
			resolved := [ parameters liveSession ] on: Error do: [ nil ].
			resolved ifNotNil: [ ^ resolved ] ].
	(parameters respondsTo: #liveSessionFromParameters)
		ifTrue: [ ^ [ parameters liveSessionFromParameters ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : 'private' }
GbsAdminSessionSupport class >> managerLoggedInSessionWithId: sessionId [
	| manager |
	sessionId ifNil: [ ^ nil ].
	manager := [ GBSM managerIfPresent ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	^ [ manager loggedInSessions
		detect: [ :each | (self sessionIdFrom: each) = sessionId ]
		ifNone: [ nil ] ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsAdminSessionSupport class >> managerSessionWithId: sessionId [
	| manager |
	sessionId ifNil: [ ^ nil ].
	manager := [ GBSM managerIfPresent ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	^ [ manager sessionWithId: sessionId ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsAdminSessionSupport class >> publishCurrentSession: session [
	session ifNil: [ ^ nil ].
	[ GbsSessionParameters currentSession: session ] on: Error do: [ ].
	[ GBSM currentSession: session ] on: Error do: [ ].
	^ session
]

{ #category : 'private' }
GbsAdminSessionSupport class >> resolveLiveSessionFrom: anObject [
	| sessionId resolved |
	resolved := self liveSessionFromCandidate: anObject.
	(self isUsableSession: resolved) ifTrue: [ ^ resolved ].

	sessionId := self sessionIdFrom: anObject.
	sessionId ifNil: [ ^ nil ].

	resolved := self currentManagerSession.
	((self sessionIdFrom: resolved) = sessionId and: [ self isUsableSession: resolved ])
		ifTrue: [ ^ resolved ].

	resolved := self managerSessionWithId: sessionId.
	(self isUsableSession: resolved) ifTrue: [ ^ resolved ].
	resolved := self managerLoggedInSessionWithId: sessionId.
	(self isUsableSession: resolved) ifTrue: [ ^ resolved ].
	^ nil
]

{ #category : 'private' }
GbsAdminSessionSupport class >> searchedManagerCurrentSession [
	| manager |
	manager := [ GBSM managerIfPresent ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	^ [ manager searchForCurrentSession ] on: Error do: [ nil ]
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
	(GbsSessionParameters respondsTo: #allParameters) ifTrue: [
		GbsSessionParameters allParameters do: [ :each |
			| session |
			session := self usableSessionFromCandidate: each.
			session ifNotNil: [ ^ session ] ] ].
	^ nil
]
