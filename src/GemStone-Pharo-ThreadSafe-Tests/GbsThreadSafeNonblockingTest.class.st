"
Live integration tests for the non-blocking / fork-detach thread-safe GCI path
(GciTsNbExecute / GciTsNbPoll / GciTsNbResult), ported from PharoGemStoneFFI.

Non-blocking execution lets long server-side work run without freezing the Pharo
process, and execute-and-detach forks work on the gem that survives client logout.

Live: require a running stone via GS_USER / GS_PASS. Without credentials the tests
are skipped. Test methods are filed under the 'integration tests' protocol so they
run in the live lane.
"
Class {
	#name : 'GbsThreadSafeNonblockingTest',
	#superclass : 'TestCase',
	#instVars : [
		'params'
	],
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'running' }
GbsThreadSafeNonblockingTest >> interface [
	^ params gciTsInterface
]

{ #category : 'running' }
GbsThreadSafeNonblockingTest >> setUp [
	super setUp.
	params := CoreGbsLiveSessionTestSupport newParametersFromEnvironment.
	params ifNil: [ ^ self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ].
	params loginThreadSafe
]

{ #category : 'running' }
GbsThreadSafeNonblockingTest >> tearDown [
	params ifNotNil: [ [ params logoutThreadSafe ] on: Error do: [ :e | ] ].
	super tearDown
]

{ #category : 'integration tests' }
GbsThreadSafeNonblockingTest >> testNonblockingExecuteReturnsImmediateResult [
	"Start a non-blocking execute and block for its (SmallInteger) result."
	self assert: (self interface executeStringNb: '6 * 7').
	self assert: self interface blockAndFetchNbResult equals: 42
]

{ #category : 'integration tests' }
GbsThreadSafeNonblockingTest >> testNonblockingExecuteReturnsStringResult [
	"A non-blocking execute whose result is a non-immediate byte object materializes
	via GciTsFetchObjInfo."
	self assert: (self interface executeStringNb: '(6 * 7) printString').
	self assert: self interface blockAndFetchNbResult equals: '42'
]

{ #category : 'integration tests' }
GbsThreadSafeNonblockingTest >> testNonblockingPollReportsCompletion [
	"Poll the call to completion before fetching its result."
	| done |
	self assert: (self interface executeStringNb: '6 * 7').
	done := false.
	[ done ] whileFalse: [ done := self interface getNbCallStatusWithMaxDelay: 100 ].
	self assert: done.
	self assert: self interface blockAndFetchNbResult equals: 42
]

{ #category : 'integration tests' }
GbsThreadSafeNonblockingTest >> testExecuteAndDetachStarts [
	"Fork-and-detach a trivial server action; it returns true once started. The
	detach leaves a non-blocking operation in progress on the session, so we collect
	its result rather than issuing a conflicting call."
	self assert: (self interface executeStringAndDetachNb: '1 + 1').
	"Drain the pending non-blocking operation so the session is clean for tearDown."
	[ self interface getNbCallStatusWithMaxDelay: 100 ]
		on: Error do: [ :ex | "detached gem may not report through Nb result; ignore" ]
]
