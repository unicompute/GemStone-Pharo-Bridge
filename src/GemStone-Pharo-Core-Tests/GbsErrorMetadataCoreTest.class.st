Class {
	#name : 'GbsErrorMetadataCoreTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsErrorMetadataCoreTest >> testDebuggerMetadataHasStandardDiagnosticShape [
	| error metadata text |
	error := GbsError new
		messageText: 'boom';
		serverProcessOop: 9001;
		exceptionOop: 9101;
		yourself.

	metadata := error debuggerMetadata.
	self assert: (metadata at: #messageText) equals: 'boom'.
	self assert: (metadata at: #processOop) equals: 9001.
	self assert: (metadata at: #serverProcessOop) equals: 9001.
	self assert: (metadata at: #exceptionOop) equals: 9101.
	self assert: (metadata includesKey: #exceptionClass).
	self assert: (metadata includesKey: #selector).
	self assert: (metadata includesKey: #source).
	self assert: (metadata includesKey: #stackDigest).
	self assert: (metadata includesKey: #dirtyTransaction).

	text := error debuggerMetadataString.
	self assert: (text includesSubstring: 'processOop=9001').
	self assert: (text includesSubstring: 'exceptionOop=9101')
]
