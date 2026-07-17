"
A drop-in replacement for GbsSession that routes ALL operations through the
thread-safe GCI interface (GciTs*) using explicit session pointers — no global
current-session state, no GciAccessMutex, no 'Could not activate GemStone GCI
session N' race.

GbsThreadSafeSession implements the subset of the GbsSession surface that
okzulu's forwarding gateway drives: evaluate / evaluateAndFetchString (string
round-trips with dynamic buffer sizing), commitTransaction / abortTransaction,
logout, isLoggedIn / isConnected, and the capability probe
requiresPreProxyResidentRepositorySymbolDispatch (always true — the adapter
uses string-based reads, never GbsProxy materialization).

Selectors NOT implemented here (classHistoryOf:, resolveSymbol:,
fetchObject:, faultFetchObjectForOop:level:, localSequenceableCollectionFrom:,
serverInterface) are intentionally absent so that respondsTo: returns false —
okzulu's RemoteClassCache and materialization paths check respondsTo: first and
fall through to the string-based / nil paths gracefully.

Instance Variables:
	sessionParameters - the GbsSessionParameters that holds the GbsThreadSafeInterface
	loggedInFlag      - local mirror of login state (set by isLoggedIn: / loggedIn: / connected:)
	localSessionOop   - local OOP value (set by sessionOop:; unused for thread-safe GCI)
	localSessionId    - a local identifier (the params identityHash) used by session-dead tracking
"
Class {
	#name : 'GbsThreadSafeSession',
	#superclass : 'Object',
	#instVars : [
		'sessionParameters',
		'loggedInFlag',
		'localSessionOop',
		'localSessionId'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'instance creation' }
GbsThreadSafeSession class >> forParameters: aGbsSessionParameters [
	"Log in via the thread-safe interface and answer a session adapter."
	aGbsSessionParameters loginThreadSafe.
	^ self new
		sessionParameters: aGbsSessionParameters;
		initializeDefaults;
		yourself
]

{ #category : 'accessing' }
GbsThreadSafeSession >> sessionParameters: anObject [
	sessionParameters := anObject
]

{ #category : 'private' }
GbsThreadSafeSession >> initializeDefaults [
	localSessionId := sessionParameters identityHash.
	loggedInFlag := true.
	localSessionOop := nil
]

{ #category : 'private' }
GbsThreadSafeSession >> interface [
	"The thread-safe GCI interface bound to this session's parameters."
	^ sessionParameters
		ifNil: [ nil ]
		ifNotNil: [ sessionParameters gciTsInterface ]
]

{ #category : 'evaluating' }
GbsThreadSafeSession >> evaluateAndFetchString: aString [
	"Execute aString and return the result string in a single round trip via
	the thread-safe interface with dynamic buffer sizing. This is the primary
	read primitive for resident-repository snapshot reads."

	^ self interface
		ifNil: [ self error: 'thread-safe session is not logged in' ]
		ifNotNil: [ :iface | iface executeAndFetchStringDynamic: aString ]
]

{ #category : 'evaluating' }
GbsThreadSafeSession >> evaluate: aString [
	"Execute aString and return the result. For byte-object results
	(String/ByteArray/Symbol), returns the fetched bytes. For immediate results
	(SmallInteger/Boolean/nil), returns the local value. Other object shapes
	signal GbsUnsupportedThreadSafeResultError instead of masquerading as nil.
	Errors propagate to the caller (callers have their own on: Error do:
	handlers for retry / discard logic)."

	^ self interface
		ifNil: [ self error: 'thread-safe session is not logged in' ]
		ifNotNil: [ :iface | iface executeAndFetchStringDynamic: aString ]
]

{ #category : 'transactions' }
GbsThreadSafeSession >> commitTransaction [
	^ self interface commit
]

{ #category : 'transactions' }
GbsThreadSafeSession >> commitTransactionOrSignalConflict [
	^ self interface commit
]

{ #category : 'transactions' }
GbsThreadSafeSession >> abortTransaction [
	^ self interface abort
]

{ #category : 'transactions' }
GbsThreadSafeSession >> abort [
	^ self interface abort
]

{ #category : 'connection' }
GbsThreadSafeSession >> logout [
	"Log out the thread-safe session and clear local state."
	sessionParameters ifNotNil: [
		sessionParameters logoutThreadSafe ].
	loggedInFlag := false
]

{ #category : 'connection' }
GbsThreadSafeSession >> disconnect [
	^ self logout
]

{ #category : 'connection' }
GbsThreadSafeSession >> resetAfterLogout [
	"Clear local state after the session has been logged out or marked dead."
	loggedInFlag := false.
	localSessionOop := nil
]

{ #category : 'testing' }
GbsThreadSafeSession >> isLoggedIn [
	"True if the local flag is set AND the thread-safe interface is still alive."
	loggedInFlag == false ifTrue: [ ^ false ].
	^ self interface
		ifNil: [ false ]
		ifNotNil: [ :iface | iface isLoggedIn ]
]

{ #category : 'testing' }
GbsThreadSafeSession >> isConnected [
	^ self isLoggedIn
]

{ #category : 'testing' }
GbsThreadSafeSession >> connected [
	^ self isLoggedIn
]

{ #category : 'accessing - state setters' }
GbsThreadSafeSession >> isLoggedIn: aBoolean [
	"Called by markSessionDead: to reflect death locally."
	loggedInFlag := aBoolean == true
]

{ #category : 'accessing - state setters' }
GbsThreadSafeSession >> loggedIn: aBoolean [
	loggedInFlag := aBoolean == true
]

{ #category : 'accessing - state setters' }
GbsThreadSafeSession >> connected: aBoolean [
	loggedInFlag := aBoolean == true
]

{ #category : 'accessing' }
GbsThreadSafeSession >> sessionId [
	"A local identifier for session-dead tracking. Not a GCI session id."
	^ localSessionId
]

{ #category : 'accessing' }
GbsThreadSafeSession >> sessionOop: anObject [
	"Stored locally for compatibility; thread-safe GCI does not use sessionOop."
	localSessionOop := anObject
]

{ #category : 'capabilities' }
GbsThreadSafeSession >> requiresPreProxyResidentRepositorySymbolDispatch [
	"Always true — the thread-safe adapter uses string-based reads exclusively,
	never GbsProxy materialization. This makes okzulu's RemoteClassCache take the
	string-based class-resolution path and the RemoteDispatcher take the
	symbol-based snapshot path, bypassing all proxy/object-API code."

	^ true
]

{ #category : 'testing' }
GbsThreadSafeSession >> passesLivenessProbe [
	"True only when this session can complete a trivial round trip RIGHT NOW.
	 isLoggedIn here is loggedInFlag AND interface session notNil -- neither
	 detects a dead gem (OkZulu audit 2026-07-17). Cheap round trip; embedders
	 call this at session hand-out, throttled."
	^ [ (self evaluate: '6 * 7') = 42 ] on: Error do: [ :ignored | false ]
]
