Extension { #name : 'GbsLiveSessionTestSupport' }

{ #category : '*GemStone-Pharo-Core-Tests' }
GbsLiveSessionTestSupport class >> ensureSharedSession [
	| currentSession user pass stone service params session |
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
	[ self ensureTranscriptProxyInstalledOn: session ] on: Error do: [ ].
	lastUnavailableReason := nil.
	^ session
]

{ #category : '*GemStone-Pharo-Core-Tests' }
GbsLiveSessionTestSupport class >> ensureTranscriptProxyInstalledOn: aSession [
	| helperClass |
	helperClass := Smalltalk
		at: #CoreGbsLiveSessionTestSupport
		ifAbsent: [ ^ false ].
	^ helperClass ensureTranscriptProxyInstalledOn: aSession
]
