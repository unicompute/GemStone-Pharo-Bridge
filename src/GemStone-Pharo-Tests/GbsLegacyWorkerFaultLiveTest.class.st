"
Live fault tests for the LEGACY GbsSession path (Phase-1 hardening A6) -- the
path production okzulu workers ride today. Pins the client-visible contract
for the two fault families the typed hardening addressed:

- stale-session reuse after logout: raises, and the liveness probe (A1)
  answers false so a pool/gateway can recycle instead of wedging
- typed GCI error dispatch (A3): server errors raise the number-specific
  GbsError subclass with #gemStoneErrorNumber populated

Gem-death mid-conversation is covered on the thread-safe path only
(GbsWorkerFaultLiveTest): the legacy linked path invalidates the GLOBAL
current session id on such faults (issue #15), which would poison the other
live tests sharing this image.

Live: requires GS_USER / GS_PASS; skipped without credentials. Each test
logs in its own session and logs out in tearDown.
"
Class {
	#name : 'GbsLegacyWorkerFaultLiveTest',
	#superclass : 'TestCase',
	#instVars : [
		'params',
		'session',
		'previousCurrentSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsLegacyWorkerFaultLiveTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	params := CoreGbsLiveSessionTestSupport newParametersFromEnvironment.
	params ifNil: [ ^ self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ].
	session := [ params login ]
		on: Error
		do: [ :ex | ^ self skip: 'Live legacy login failed: ', ex messageText ]
]

{ #category : 'running' }
GbsLegacyWorkerFaultLiveTest >> tearDown [
	"Restore the GLOBAL current session: legacy login re-points
	 GbsSessionParameters currentSession at this test's session, and leaving
	 it on a logged-out session poisons every later test that shares the
	 global (the launcher/admin presenter suites)."
	session ifNotNil: [ [ session logout ] on: Error do: [ :ignored | ] ].
	GbsSessionParameters currentSession: previousCurrentSession.
	session := nil.
	params := nil.
	previousCurrentSession := nil.
	super tearDown
]

{ #category : 'integration tests' }
GbsLegacyWorkerFaultLiveTest >> testStaleSessionReuseAfterLogoutFailsProbe [
	"A logged-out legacy session must fail the liveness probe so the gateway
	 recycles it at hand-out instead of serving dead taps."
	self assert: session passesLivenessProbe.
	self assert: (session evaluate: '6 * 7') equals: 42.
	session logout.
	self deny: session passesLivenessProbe
]

{ #category : 'integration tests' }
GbsLegacyWorkerFaultLiveTest >> testTypedErrorNumbersSurfaceOnLegacyPath [
	"A3 contract on the legacy path: doesNotUnderstand raises
	 GbsMessageNotUnderstoodError (2010), a bad offset raises GbsOffsetError
	 (2003), each carrying the raw number via #gemStoneErrorNumber."
	[ session evaluate: 'nil fooBarSelectorNobodyImplements'.
		self signalFailure: 'expected doesNotUnderstand to raise' ]
		on: Error
		do: [ :ex |
			self assert: ex class name equals: 'GbsMessageNotUnderstoodError'.
			self assert: ex gemStoneErrorNumber equals: 2010 ].
	[ session evaluate: 'Array new at: 99'.
		self signalFailure: 'expected offset error to raise' ]
		on: Error
		do: [ :ex |
			self assert: ex class name equals: 'GbsOffsetError'.
			self assert: ex gemStoneErrorNumber equals: 2003 ]
]
