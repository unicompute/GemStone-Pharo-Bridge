Class {
	#name : 'GbsErrorFFITest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbsErrorFFITest >> requireLiveSessionAndInterface [
	| session interface |
	session := GbsSessionParameters currentSession.
	(session isNil or: [ session isConnected not ]) ifTrue: [
		self skip: 'Requires an active GemStone session' ].
	interface := GbsServerInterface uniqueInstance.
	interface ifNil: [ self skip: 'GemStone server interface unavailable' ].
	^ interface
]

{ #category : 'tests' }
GbsErrorFFITest >> test01ExecuteOnly [
	"Diagnostic: Does the crash happen DURING execution?"
	| interface |
	interface := self requireLiveSessionAndInterface.
	
	"Trigger the runtime error, but DO NOT call GciErr_"
	interface apiGciExecuteStr: 'Object thisMessageDoesNotExist' context: 20 env: 0.
	
	"If we reach this line, GciExecuteStr is innocent!"
	self assert: true.
]

{ #category : 'tests' }
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

{ #category : 'tests' }
GbsErrorFFITest >> test03ExecuteSafe [
	"Diagnostic: Can we safely execute an error without blowing up the C-stack?"
	| interface resultOop |
	
	interface := self requireLiveSessionAndInterface.
	
	"Use the new 2-argument safe execution method!"
	resultOop := interface apiGciExecuteStrSafe: 'Object thisMessageDoesNotExist' context: 20.
	
	"If GemStone safely caught the error, it will return OOP_ILLEGAL (1)."
	self assert: resultOop equals: 1.
]

{ #category : 'tests' }
GbsErrorFFITest >> testSafeErrorFetch [
	| interface cBuffer hasError errorBytes errorString |
	
	interface := self requireLiveSessionAndInterface.
	
	"1. Trigger the massive error that previously crashed Pharo"
	interface apiGciExecuteStr: 'Object thisMessageDoesNotExist' context: 20 env: 0.
	
	"2. Allocate a massive C-Array. It lives safely outside Pharo's GC heap."
	cBuffer := FFIExternalArray externalNewType: 'uint8' size: 2048.
	
	[
		"3. Fetch the error using the new safe void* signature"
		hasError := interface apiGciErrSafe: cBuffer getHandle.
		self assert: hasError description: 'C-library should report an error'.
		
		"4. Extract the 1025-byte string starting at byte 115 (1-indexed)"
		errorBytes := ByteArray new: 1024.
		1 to: 1024 do: [ :i | errorBytes at: i put: (cBuffer at: 114 + i) ].
		
		"5. Convert bytes to string and trim the C null-terminators"
		errorString := errorBytes asString copyUpTo: Character null.
		
		"6. Prove we safely caught the MessageNotUnderstood without a SegFault!"
		self assert: (errorString includesSubstring: 'doesNotUnderstand')
			  description: 'Did not correctly parse the error string'.
			  
	] ensure: [ 
		"Always free the C-memory"
		cBuffer free. 
	].
]
