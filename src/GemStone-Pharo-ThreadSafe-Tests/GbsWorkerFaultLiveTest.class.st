"
Live fault-injection tests for the worker bridge layer (Phase-1 hardening A6):
the failure modes that wedged production workers, exercised against a real
stone so the CLIENT-visible contract is pinned, not guessed.

Covered:
- stale-session reuse after logout (must raise, never silently succeed;
  liveness probe must answer false)
- gem death mid-conversation (server-side session termination while the
  client still holds a 'logged in' session object)
- login/logout churn (no session leak: repeated cycles keep working and a
  final login still succeeds)
- large and non-ASCII result fetches over the dynamic transport
- typed GCI error numbers surfacing on the thread-safe path (2010, 2003)

Live: requires GS_USER / GS_PASS (and the usual GS_* vars); skipped without
credentials. Every test logs in its OWN thread-safe session so an injected
fault can never poison another test's session.
"
Class {
	#name : 'GbsWorkerFaultLiveTest',
	#superclass : 'TestCase',
	#instVars : [
		'ownedSessions'
	],
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'running' }
GbsWorkerFaultLiveTest >> setUp [
	super setUp.
	ownedSessions := OrderedCollection new.
	CoreGbsLiveSessionTestSupport newParametersFromEnvironment
		ifNil: [ ^ self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ]
]

{ #category : 'running' }
GbsWorkerFaultLiveTest >> tearDown [
	ownedSessions do: [ :session |
		[ session logout ] on: Error do: [ :ignored | ] ].
	ownedSessions := OrderedCollection new.
	super tearDown
]

{ #category : 'private' }
GbsWorkerFaultLiveTest >> newLiveSession [
	| params session |
	params := CoreGbsLiveSessionTestSupport newParametersFromEnvironment.
	params ifNil: [ ^ self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ].
	session := [ params loginThreadSafeSession ]
		on: Error
		do: [ :ex | ^ self skip: 'Live thread-safe login failed: ', ex messageText ].
	ownedSessions add: session.
	^ session
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testStaleSessionReuseAfterLogoutRaisesAndFailsProbe [
	"A worker holding a logged-out session must get a raised error on the next
	 call and a false liveness probe -- never a silent nil result (the
	 favourite/RSVP dead-tap family started as silent stale-session reuse)."
	| session |
	session := self newLiveSession.
	self assert: session passesLivenessProbe.
	self assert: session isLoggedIn.
	session logout.
	self deny: session passesLivenessProbe.
	self deny: session isLoggedIn.
	self should: [ session evaluate: '6 * 7' ] raise: Error
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testGemDeathMidConversationFailsProbeAndRaises [
	"Simulate the nightly-bounce / crashed-gem class of failure: the SERVER
	 side of the session dies while the client still holds a session object
	 that believes it is logged in. Server-side 'System logout' terminates the
	 gem's session from within, which is exactly what the client observes when
	 its gem is killed. Every subsequent call must raise and the liveness
	 probe must answer false, so the pool/gateway recycles instead of wedging."
	| session |
	session := self newLiveSession.
	self assert: session passesLivenessProbe.
	[ session evaluate: 'System logout' ] on: Error do: [ :ignored | ].
	self deny: session passesLivenessProbe.
	self should: [ session evaluate: '1 + 1' ] raise: Error
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testLoginLogoutChurnDoesNotLeakSessions [
	"The 4039/license-ceiling incidents came from leaked gems. Repeated
	 login/logout cycles must each work and must not exhaust anything: after
	 the churn a fresh login still evaluates correctly."
	| session |
	1 to: 8 do: [ :cycle |
		session := self newLiveSession.
		self
			assert: (session evaluateAndFetchString: '(', cycle printString, ' * 3) printString')
			equals: (cycle * 3) printString.
		session logout.
		ownedSessions remove: session ifAbsent: [ ] ].
	session := self newLiveSession.
	self assert: (session evaluateAndFetchString: '(6 * 7) printString') equals: '42'
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testConcurrentIndependentSessionsDoNotInterfere [
	"GciTs is thread-safe per distinct session: three live sessions evaluate
	 independently and logging one out must not disturb the others."
	| sessions |
	sessions := (1 to: 3) collect: [ :ignored | self newLiveSession ].
	sessions withIndexDo: [ :session :index |
		self
			assert: (session evaluateAndFetchString: '(', index printString, ' + 100) printString')
			equals: (index + 100) printString ].
	(sessions at: 2) logout.
	self deny: (sessions at: 2) passesLivenessProbe.
	self assert: ((sessions at: 1) evaluateAndFetchString: '(7 * 7) printString') equals: '49'.
	self assert: ((sessions at: 3) evaluateAndFetchString: '(8 * 8) printString') equals: '64'
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testLargeStringFetchRoundTrips [
	"Dynamic-transport fetches must not truncate or corrupt large byte
	 results (the transport resolves byte classes by OOP at runtime since A5)."
	| session fetched |
	session := self newLiveSession.
	fetched := session evaluateAndFetchString: 'String new: 100000 withAll: $a'.
	self assert: fetched size equals: 100000.
	self assert: fetched first equals: $a.
	self assert: fetched last equals: $a
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testNonAsciiStringFetchRoundTrips [
	"Non-ASCII text must survive the round trip (GCI error text arrives as
	 UTF-8 bytes; result strings must decode the same way)."
	| session fetched |
	session := self newLiveSession.
	fetched := session evaluateAndFetchString: '(String new) , ''h'', (Character value: 233) asString, ''llo'''.
	self assert: fetched equals: 'h', (Character value: 233) asString, 'llo'
]

{ #category : 'integration tests' }
GbsWorkerFaultLiveTest >> testTypedErrorNumbersSurfaceOnThreadSafePath [
	"The typed error contract (A3): server errors surface as GbsGciTsError
	 carrying the raw GCI number via #gemStoneErrorNumber -- 2010 for
	 doesNotUnderstand, 2003 for a bad object offset."
	| session |
	session := self newLiveSession.
	[ session evaluate: 'nil fooBarSelectorNobodyImplements'.
		self signalFailure: 'expected doesNotUnderstand to raise' ]
		on: Error
		do: [ :ex |
			self assert: ((ex respondsTo: #gemStoneErrorNumber)
				and: [ ex gemStoneErrorNumber = 2010 ]) ].
	[ session evaluate: 'Array new at: 99'.
		self signalFailure: 'expected offset error to raise' ]
		on: Error
		do: [ :ex |
			self assert: ((ex respondsTo: #gemStoneErrorNumber)
				and: [ ex gemStoneErrorNumber = 2003 ]) ]
]
