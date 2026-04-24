Class {
	#name : 'GbsLiveSessionTestSupport',
	#superclass : 'Object',
	#classInstVars : [
		'ownedParameters',
		'ownedSession',
		'previousCurrentSession',
		'lastUnavailableReason'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbsLiveSessionTestSupport class >> ensureSharedSession [
	| currentSession user pass stone service params session |
	currentSession := GbsSessionParameters currentSession.
	(self sessionIsUsable: currentSession) ifTrue: [
		lastUnavailableReason := nil.
		^ currentSession ].
	(self sessionIsUsable: ownedSession) ifTrue: [
		GbsSessionParameters currentSession: ownedSession.
		lastUnavailableReason := nil.
		^ ownedSession ].

	user := self envAt: 'GS_USER' ifAbsent: [ '' ].
	pass := self envAt: 'GS_PASS' ifAbsent: [ '' ].
	((user isEmpty) or: [ pass isEmpty ]) ifTrue: [
		lastUnavailableReason := self missingCredentialsReason.
		^ nil ].

	stone := self envAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ].
	service := self envAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ].
	previousCurrentSession := currentSession.
	params := GbsSessionParameters new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: service.

	session := [ params login ] on: Error do: [ :ex |
		lastUnavailableReason := 'Live GemStone login failed: ', ex messageText.
		nil ].

	(self sessionIsUsable: session) ifFalse: [
		[ params logout ] on: Error do: [ ].
		GbsSessionParameters currentSession: currentSession.
		ownedParameters := nil.
		ownedSession := nil.
		^ nil ].

	ownedParameters := params.
	ownedSession := session.
	lastUnavailableReason := nil.
	^ session
]

{ #category : 'private' }
GbsLiveSessionTestSupport class >> envAt: key ifAbsent: aBlock [
	^ [ (self osEnvironment at: key ifAbsent: aBlock) asString ]
		on: Error
		do: [ aBlock value ]
]

{ #category : 'private' }
GbsLiveSessionTestSupport class >> osEnvironment [
	^ [ Smalltalk os environment ]
		on: Error
		do: [ [ OSEnvironment current ]
			on: Error
			do: [ Dictionary new ] ]
]

{ #category : 'private' }
GbsLiveSessionTestSupport class >> missingCredentialsReason [
	^ 'Set GS_USER and GS_PASS to run live GemStone integration tests'
]

{ #category : 'private' }
GbsLiveSessionTestSupport class >> releaseOwnedSession [
	| params priorSession |
	ownedParameters ifNil: [
		lastUnavailableReason := nil.
		^ self ].

	params := ownedParameters.
	priorSession := previousCurrentSession.
	ownedParameters := nil.
	ownedSession := nil.
	previousCurrentSession := nil.
	lastUnavailableReason := nil.

	[ params logout ] on: Error do: [ ].
	GbsSessionParameters currentSession: priorSession
]

{ #category : 'private' }
GbsLiveSessionTestSupport class >> sessionIsUsable: aSession [
	aSession ifNil: [ ^ false ].
	(aSession respondsTo: #isConnected) ifFalse: [ ^ false ].
	([ aSession isConnected = true ] on: Error do: [ false ]) ifFalse: [ ^ false ].
	(aSession respondsTo: #isLoggedIn) ifFalse: [ ^ false ].
	([ aSession isLoggedIn = true ] on: Error do: [ false ]) ifFalse: [ ^ false ].
	^ (aSession respondsTo: #evaluate:)
		or: [ aSession respondsTo: #execute: ]
]

{ #category : 'accessing' }
GbsLiveSessionTestSupport class >> unavailableReason [
	^ lastUnavailableReason ifNil: [ self missingCredentialsReason ]
]
