Class {
	#name : 'CoreGbsLiveSessionTestSupport',
	#superclass : 'Object',
	#classInstVars : [
		'ownedParameters',
		'ownedSession',
		'previousCurrentSession',
		'lastUnavailableReason'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> ensureSharedSession [
	| currentSession user pass stone service netldiHost netldiNameOrPort params session |
	currentSession := GbsSessionParameters currentSession.
	(self sessionIsUsable: currentSession) ifTrue: [
		[ self ensureTranscriptProxyInstalledOn: currentSession ] on: Error do: [ ].
		lastUnavailableReason := nil.
		^ currentSession ].
	(self sessionIsUsable: ownedSession) ifTrue: [
		GbsSessionParameters currentSession: ownedSession.
		[ self ensureTranscriptProxyInstalledOn: ownedSession ] on: Error do: [ ].
		lastUnavailableReason := nil.
		^ ownedSession ].

	user := self envAt: 'GS_USER' ifAbsent: [ '' ].
	pass := self envAt: 'GS_PASS' ifAbsent: [ '' ].
	((user isEmpty) or: [ pass isEmpty ]) ifTrue: [
		lastUnavailableReason := self missingCredentialsReason.
		^ nil ].

	stone := self envAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ].
	service := self envAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ].
	netldiHost := self envAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ].
	netldiNameOrPort := self envAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ].
	previousCurrentSession := currentSession.
	params := GbsSessionParameters new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: service.
	netldiHost isEmpty ifFalse: [ params netldiHostOrIp: netldiHost ].
	netldiNameOrPort isEmpty ifFalse: [ params netldiNameOrPort: netldiNameOrPort ].

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
	[ self ensureTranscriptProxyInstalledOn: session ] on: Error do: [ ].
	lastUnavailableReason := nil.
	^ session
]

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> ensureTranscriptProxyInstalledOn: aSession [
	| script |
	aSession ifNil: [ ^ false ].
	script := '
	| tempDict proxyClass |
	proxyClass := Smalltalk at: #Transcript ifAbsent: [ nil ].
	(proxyClass isNil or: [ proxyClass isBehavior not ]) ifTrue: [
		tempDict := SymbolDictionary new name: #PharoSessionGlobals.
		System myUserProfile insertDictionary: tempDict at: 1.
		proxyClass := Object subclass: <quote>PharoTranscriptProxy<quote>
			instVarNames: #()
			classVars: #()
			classInstVars: #(<quote>currentLine<quote>)
			poolDictionaries: #()
			inDictionary: tempDict
			options: #().
		tempDict at: #Transcript put: proxyClass ].
	proxyClass class compileMethod: <quote>show: aString
		currentLine := (currentLine ifNil: [ <quote><quote> ]), aString asString.<quote> category: <quote>logging<quote>.
	proxyClass class compileMethod: <quote>cr
		| log |
		log := UserGlobals at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		log add: (currentLine ifNil: [ <quote><quote> ]).
		currentLine := <quote><quote>.<quote> category: <quote>logging<quote>.
	proxyClass class compileMethod: <quote>fetchAndClear
		| log text |
		log := UserGlobals at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		text := String streamContents: [ :stream |
			log do: [ :each |
				stream nextPutAll: each asString.
				stream cr ] ].
		UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
		^ text<quote> category: <quote>logging<quote>.
	UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
	true
	' copyReplaceAll: '<quote>' with: ''''.
	^ [ aSession evaluate: script ] on: Error do: [ false ]
]

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> envAt: key ifAbsent: aBlock [
	^ [ (self osEnvironment at: key ifAbsent: aBlock) asString ]
		on: Error
		do: [ aBlock value ]
]

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> osEnvironment [
	^ [ Smalltalk os environment ]
		on: Error
		do: [ [ OSEnvironment current ]
			on: Error
			do: [ Dictionary new ] ]
]

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> missingCredentialsReason [
	^ 'Set GS_USER and GS_PASS to run live GemStone integration tests'
]

{ #category : 'private' }
CoreGbsLiveSessionTestSupport class >> releaseOwnedSession [
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
CoreGbsLiveSessionTestSupport class >> sessionIsUsable: aSession [
	aSession ifNil: [ ^ false ].
	(aSession respondsTo: #isConnected) ifFalse: [ ^ false ].
	([ aSession isConnected = true ] on: Error do: [ false ]) ifFalse: [ ^ false ].
	(aSession respondsTo: #isLoggedIn) ifFalse: [ ^ false ].
	([ aSession isLoggedIn = true ] on: Error do: [ false ]) ifFalse: [ ^ false ].
	^ (aSession respondsTo: #evaluate:)
		or: [ aSession respondsTo: #execute: ]
]

{ #category : 'accessing' }
CoreGbsLiveSessionTestSupport class >> unavailableReason [
	^ lastUnavailableReason ifNil: [ self missingCredentialsReason ]
]
