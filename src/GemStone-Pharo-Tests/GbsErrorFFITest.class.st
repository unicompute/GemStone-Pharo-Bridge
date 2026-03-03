Class {
	#name : 'GbsErrorFFITest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsErrorFFITest >> testSafeErrorFetch [
	| interface cBuffer hasError errorBytes errorString |
	
	interface := GbsServerInterface uniqueInstance.
	
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
