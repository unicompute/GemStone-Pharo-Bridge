"
Demonstrates that the thread-safe GCI path (GbsThreadSafeInterface) is free of the
global current-session race that the legacy linked GCI suffers from.

The legacy path keeps the current session in per-process C state set by
GciSetSessionId_; concurrent green processes can interleave their
(set-session, execute) pairs and produce 'Could not activate GemStone GCI session N'
or run a call against the wrong session. The bridge works around this with the
image-wide GciAccessMutex. The thread-safe path passes an explicit GciSession
pointer to every call, so no such global exists and interleaved requests across
distinct sessions remain session-correct. The bridge may still serialize FFI
calls for library-binding safety; these tests prove isolation, not throughput.

These are live tests: they require a running stone reachable via GS_USER / GS_PASS
(and the usual GS_* connection vars). Without credentials they are skipped.
"
Class {
	#name : 'GbsThreadSafeConcurrencyTest',
	#superclass : 'TestCase',
	#instVars : [
		'sessions'
	],
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'running' }
GbsThreadSafeConcurrencyTest >> newLoggedInSession [
	"Build a fresh session from the environment and log it in via the thread-safe
	path. Answer the GbsSessionParameters, or nil if credentials are unavailable."
	| params |
	params := CoreGbsLiveSessionTestSupport newParametersFromEnvironment.
	params ifNil: [ ^ nil ].
	params loginThreadSafe.
	sessions add: params.
	^ params
]

{ #category : 'running' }
GbsThreadSafeConcurrencyTest >> setUp [
	super setUp.
	sessions := OrderedCollection new
]

{ #category : 'running' }
GbsThreadSafeConcurrencyTest >> skipOrCredentials [
	"Answer parameters if credentials exist, otherwise skip the test."
	(CoreGbsLiveSessionTestSupport newParametersFromEnvironment) ifNil: [
		self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ]
]

{ #category : 'running' }
GbsThreadSafeConcurrencyTest >> tearDown [
	sessions do: [ :each |
		[ each logoutThreadSafe ] on: Error do: [ :e | ] ].
	super tearDown
]

{ #category : 'tests' }
GbsThreadSafeConcurrencyTest >> testConcurrentExecutesDoNotClobberSessions [
	"Log in N independent sessions and hammer them concurrently. Each session asks
	the gem for a value derived from its own index; if the global-session race
	existed here, calls would fail to activate or return another session's value.
	No legacy current-session activation is used on this path."
	| n results errors processes done |
	self skipOrCredentials.
	n := 6.
	results := Array new: n withAll: nil.
	errors := OrderedCollection new.
	processes := OrderedCollection new.
	done := Semaphore new.

	1 to: n do: [ :i |
		| sess |
		sess := self newLoggedInSession.
		processes add: ([
			[ | answer |
				"Each session computes i*1000+i so a cross-talk would be obvious."
				answer := sess evaluateAndFetchStringThreadSafe:
					('(' , (i * 1000 + i) printString , ') printString').
				results at: i put: answer ]
				on: Error
				do: [ :e | errors add: i -> e messageText ].
			done signal ] fork) ].

	n timesRepeat: [ done wait ].

	self assert: errors isEmpty
		description: ('Concurrent thread-safe executes raised: ' , errors printString).
	1 to: n do: [ :i |
		self
			assert: (results at: i) = (i * 1000 + i) printString
			description: ('Session ' , i printString , ' got the wrong result ('
				, (results at: i) printString , ') -- a sign of cross-session clobbering') ]
]

{ #category : 'tests' }
GbsThreadSafeConcurrencyTest >> testSingleSessionExecuteAndFetch [
	"Smoke test the hot path itself before exercising concurrency."
	| sess |
	self skipOrCredentials.
	sess := self newLoggedInSession.
	self
		assert: (sess evaluateAndFetchStringThreadSafe: '(2 + 2) printString')
		equals: '4'
]
