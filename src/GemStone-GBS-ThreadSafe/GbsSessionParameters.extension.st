Extension { #name : 'GbsSessionParameters' }

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> loginThreadSafeSession [
	"Log in via the thread-safe interface and answer a GbsThreadSafeSession
	adapter that implements the GbsSession surface. This is the drop-in
	replacement for #login — callers get a session object that responds to
	evaluate: / evaluateAndFetchString: / commitTransaction / abortTransaction /
	logout / isLoggedIn with the same selectors as GbsSession, but all
	operations route through explicit GciSession pointers (no global current
	session, no GciAccessMutex, no activation race)."

	^ GbsThreadSafeSession forParameters: self
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> gciTsInterface [
	"The thread-safe GCI interface bound to this session, or nil if this session
	was not logged in via loginThreadSafe. Held in a transient registry on
	GbsThreadSafeInterface to avoid mutating the converted class definition (and
	its serialization) during the prototype; the eventual migration adds a proper
	instance variable instead."
	^ GbsThreadSafeInterface interfaceForSession: self
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> loginThreadSafe [
	"Prototype thread-safe login: one GciTsLogin call, no GciSetNet/GciInit/
	GciEncrypt and no global current-session state. Stores the resulting
	GbsThreadSafeInterface (holding the GciSession pointer) on this session.

	This is a parallel path to #login; it does not touch sessionId or
	CurrentSession, so the legacy linked-GCI path is unaffected."
	| interface |
	self restoreRememberedSecretsFromKeychain.
	self validateForLogin.
	interface := GbsThreadSafeInterface new.
	interface
		loginStoneNrs: self gemStoneName
		gemNrs: self gciGemServiceString
		gsUser: self username
		gsPassword: self password
		hostUser: (self hostUsername ifNil: [ '' ])
		hostPassword: (self hostPassword ifNil: [ '' ]).
	GbsThreadSafeInterface interfaceForSession: self put: interface.
	^ self
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> evaluateAndFetchStringThreadSafe: aString [
	"Thread-safe counterpart to #evaluateAndFetchString:. Executes aString and
	returns the result string in a single round trip, against this session's
	explicit GciSession pointer -- no GciAccessMutex required."
	| interface |
	interface := self gciTsInterface.
	interface ifNil: [ ^ self error: 'session is not logged in via loginThreadSafe' ].
	^ interface executeAndFetchString: aString
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> commitThreadSafe [
	| interface |
	interface := self gciTsInterface.
	interface ifNil: [ ^ self error: 'session is not logged in via loginThreadSafe' ].
	^ interface commit
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> abortThreadSafe [
	| interface |
	interface := self gciTsInterface.
	interface ifNil: [ ^ self error: 'session is not logged in via loginThreadSafe' ].
	^ interface abort
]

{ #category : '*GemStone-GBS-ThreadSafe' }
GbsSessionParameters >> logoutThreadSafe [
	| interface |
	interface := self gciTsInterface.
	interface ifNil: [ ^ self ].
	interface logout.
	GbsThreadSafeInterface removeInterfaceForSession: self.
	^ self
]
