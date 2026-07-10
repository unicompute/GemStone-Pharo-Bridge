"
Live integration tests for the thread-safe GCI session path (GbsThreadSafeInterface).

These exercise the exact abort/execute cycles that permanently kill a legacy
linked-GCI session: the legacy GciAbort() invalidates the global current session
id so the next GciSetSessionId_ fails (issue #15). The thread-safe path passes an
explicit GciSession pointer to GciTsAbort / GciTsExecute_, so it survives repeated
abort+execute and is the migration target for the live lane.

Live: require a running stone via GS_USER / GS_PASS (and the usual GS_* vars).
Without credentials the tests are skipped. Test methods are filed under the
'integration tests' protocol so they run in the live lane.
"
Class {
	#name : 'GbsThreadSafeLiveSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'params'
	],
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'running' }
GbsThreadSafeLiveSessionTest >> interface [
	^ params gciTsInterface
]

{ #category : 'running' }
GbsThreadSafeLiveSessionTest >> setUp [
	super setUp.
	params := CoreGbsLiveSessionTestSupport newParametersFromEnvironment.
	params ifNil: [ ^ self skip: CoreGbsLiveSessionTestSupport missingCredentialsReason ].
	params loginThreadSafe
]

{ #category : 'running' }
GbsThreadSafeLiveSessionTest >> tearDown [
	params ifNotNil: [ [ params logoutThreadSafe ] on: Error do: [ :e | ] ].
	super tearDown
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testAbortDoesNotKillSession [
	"The legacy GciAbort() invalidates the session id; GciTsAbort must not. Abort
	then execute several times and confirm each round still works."
	self interface abort.
	self assert: (self interface executeAndFetchString: '(2 + 2) printString') equals: '4'.
	1 to: 3 do: [ :i |
		self interface abort.
		self
			assert: (self interface executeAndFetchString: '(' , (i * 10) printString , ') printString')
			equals: (i * 10) printString ]
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testCommitThenExecuteSurvives [
	"GciTsCommit reaches the gem and the session keeps working afterwards. The gem
	may legitimately reject the commit itself (e.g. a restore from backup/tran logs
	is in progress, error 2248); that is a server-state condition, not a session
	failure, so tolerate it and still assert the session is alive."
	[ self interface commit ]
		on: GbsGciTsError
		do: [ :ex | "server-state rejection is acceptable" ].
	self assert: (self interface executeAndFetchString: '(3 + 4) printString') equals: '7'
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testExecuteScriptAndReturnOopReturnsImmediateOop [
	"GciTsExecute_ returns the result object's OOP. For a SmallInteger result the
	OOP is a tagged immediate; oopIsSmallInt:/asLocalObject: must decode it back to
	the integer value."
	| oop |
	oop := self interface executeScriptAndReturnOop: '7 * 6'.
	self assert: oop isInteger.
	self assert: (self interface class oopIsSmallInt: oop).
	self assert: (self interface class asLocalObject: oop) equals: 42
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testExecuteScriptAndReturnOopForObjectIsValidOop [
	"A non-immediate result (an Array) returns a real (even, non-special) object OOP."
	| oop |
	oop := self interface executeScriptAndReturnOop: '{ 1 . 2 . nil }'.
	self assert: oop isInteger.
	self assert: oop > 20
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testDynamicFetchReturnsLargeByteArrayWithoutTruncation [
	"Exercise the refetch path above the 8 KiB probe capacity and preserve the
	remote byte-object type."
	| result expected |
	result := self interface executeAndFetchStringDynamic:
		'ByteArray new: 16384 withAll: 165'.
	expected := ByteArray new: 16384 withAll: 165.
	self assert: result class equals: ByteArray.
	self assert: result equals: expected
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testDynamicFetchReturnsLargeStringWithoutTruncation [
	"Exercise the refetch path above the 8 KiB probe capacity and verify both
	ends of the payload by comparing the complete value."
	| result expected |
	result := self interface executeAndFetchStringDynamic:
		'String new: 16384 withAll: $x'.
	expected := String new: 16384 withAll: $x.
	self assert: result class equals: ByteString.
	self assert: result equals: expected
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testDynamicFetchSignalsForNonByteObject [
	"The dynamic adapter deliberately materializes only immediate and byte-format
	results; unsupported objects must not masquerade as a legitimate remote nil."
	self
		should: [ self interface executeAndFetchStringDynamic: '{ 1 . 2 . 3 }' ]
		raise: GbsUnsupportedThreadSafeResultError
]

{ #category : 'integration tests' }
GbsThreadSafeLiveSessionTest >> testDynamicFetchReturnsSymbolAsSymbol [
	| result |
	result := self interface executeAndFetchStringDynamic: '#threadSafeDynamicFetch'.
	self assert: result isSymbol.
	self assert: result equals: #threadSafeDynamicFetch
]
