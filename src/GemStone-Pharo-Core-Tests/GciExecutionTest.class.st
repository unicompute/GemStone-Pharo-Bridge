Class {
	#name : 'GciExecutionTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'integration tests' }
GciExecutionTest >> testRawCExecution [
	| interface session cString result |
	interface := GbsServerInterface uniqueInstance.
	session := GbsLiveSessionTestSupport ensureSharedSession.
	session ifNil: [
		self skip: GbsLiveSessionTestSupport unavailableReason ].
	interface ifNil: [ self skip: 'GemStone server interface unavailable' ].
	
	"1. SAFELY ALLOCATE IN C-HEAP: Hides the string from Pharo's Garbage Collector"
	cString := ExternalAddress fromString: '1+1'.
	
	[
		"2. Execute asynchronously on the UFFI worker thread. 20 = OOP_NIL"
		result := interface apiGciExecuteStr: cString context: 20 environment: 0.
	] ensure: [ 
		"3. CRITICAL: Free the C-memory to prevent leaks"
		cString free.
	].
	
	"4. Assert that GemStone returned the OOP for 2 (which is 18)"
	self assert: result equals: 18.
]
