Extension { #name : 'GbsProxy' }

{ #category : '*GemStone-GBS-Core' }
GbsProxy class >> oop: anInteger session: aGbsSession [
	| proxy |
	proxy := self basicNew.
	proxy oop: anInteger.
	proxy session: aGbsSession.
	^ GbsProxyLifecycle registerProxy: proxy forSession: aGbsSession
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> == anObject [
	"Direct identity check using the Pharo identity primitive"

	<primitive: 110>
	((anObject respondsTo: #oop) and: [ anObject respondsTo: #session ])
		ifFalse: [ ^ false ].
	^ [ self oop = anObject oop and: [ self session == anObject session ] ]
		on: Error
		do: [ false ]
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> class [
	^ super class
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> ensureSessionIsUsable [
	session ifNil: [
		GbsError signal: 'GemStone proxy has no session.' ].
	((session respondsTo: #isLoggedIn) and: [ session isLoggedIn ~= true ]) ifTrue: [
		GbsError signal: 'GemStone proxy session is disconnected.' ].
	(GbsProxyLifecycle isProxyCurrent: self forSession: session) ifFalse: [
		GbsError signal: 'GemStone proxy belongs to a previous session lifecycle.' ].
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> fault [
	self ensureSessionIsUsable.
	^ session faultProxy: self
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> faultToLevel: levelOrNil [
	^ self fault
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> isKindOf: aClass [
	"Shield this from doesNotUnderstand:"
	(aClass respondsTo: #inheritsFrom:) ifFalse: [ ^ false ].
	^ (self class == aClass) or: [ self class inheritsFrom: aClass ]
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> isMemberOf: aClass [
	^ self class == aClass
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> respondsTo: aSymbol [
	^ self class canUnderstand: aSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> stubYourself [
	^ self
]
