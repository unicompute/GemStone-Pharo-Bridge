Class {
	#name : 'GbsErrorFFITest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbsErrorFFITest >> requireLiveSessionAndInterface [
	| session interface |
	session := GbsLiveSessionTestSupport ensureSharedSession.
	session ifNil: [
		self skip: GbsLiveSessionTestSupport unavailableReason ].
	interface := GbsServerInterface uniqueInstance.
	interface ifNil: [ self skip: 'GemStone server interface unavailable' ].
	^ interface
]

{ #category : 'integration tests' }
GbsErrorFFITest >> test01ExecuteOnly [
	"Diagnostic: Does the crash happen DURING execution?"
	| interface |
	interface := self requireLiveSessionAndInterface.
	
	"Trigger the runtime error, but DO NOT call GciErr_"
	interface apiGciExecuteStr: 'Object thisMessageDoesNotExist' context: 20 env: 0.
	
	"If we reach this line, GciExecuteStr is innocent!"
	self assert: true.
]

{ #category : 'integration tests' }
GbsErrorFFITest >> test02ErrorWithExternalAddress [
	"Diagnostic: Does the crash happen DURING error fetching?"
	| interface cBuffer hasError |
	interface := self requireLiveSessionAndInterface.
	
	interface apiGciExecuteStr: 'Object thisMessageDoesNotExist' context: 20 env: 0.
	
	"Allocate 8 Kilobytes of raw C-memory. Impossible to overflow."
	cBuffer := ExternalAddress allocate: 8192.
	
	[
		hasError := interface apiGciErrAddress: cBuffer.
		self assert: hasError description: 'Should flag an error'.
	] ensure: [ 
		cBuffer free. 
	].
]

{ #category : 'integration tests' }
GbsErrorFFITest >> test03ExecuteSafe [
	"Diagnostic: Can we safely execute an error without blowing up the C-stack?"
	| interface resultOop |
	
	interface := self requireLiveSessionAndInterface.
	
	"Use the new 2-argument safe execution method!"
	resultOop := interface apiGciExecuteStrSafe: 'Object thisMessageDoesNotExist' context: 20.
	
	"If GemStone safely caught the error, it will return OOP_ILLEGAL (1)."
	self assert: resultOop equals: 1.
]

{ #category : 'integration tests' }
GbsErrorFFITest >> testSafeErrorFetch [
	| interface cBuffer hasError errorString |
	
	interface := self requireLiveSessionAndInterface.
	
	"1. Trigger the massive error that previously crashed Pharo"
	interface apiGciExecuteStr: 'Object thisMessageDoesNotExist' context: 20 env: 0.
	
	"2. Allocate the raw error buffer outside the image heap."
	cBuffer := ExternalAddress allocate: 2168.
	
	[
		"3. Fetch the error using the new safe void* signature"
		hasError := interface apiGciErrSafe: cBuffer.
		self assert: hasError description: 'C-library should report an error'.
		
		"4. Extract the C string payload from the known message offset"
		errorString := ((cBuffer + 113) readString) asString.
		
		"5. Prove we safely caught the MessageNotUnderstood without a SegFault!"
		self
			assert: ((errorString includesSubstring: 'MessageNotUnderstood')
				or: [ errorString includesSubstring: 'thisMessageDoesNotExist' ])
			description: 'Did not correctly parse the error string'.
			  
	] ensure: [ 
		"Always free the C-memory"
		cBuffer free. 
	].
]
