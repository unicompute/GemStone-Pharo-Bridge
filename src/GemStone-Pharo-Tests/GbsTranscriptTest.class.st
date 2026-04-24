Class {
	#name : 'GbsTranscriptTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'integration tests' }
GbsTranscriptTest >> testLiveTranscriptFetch [
	| session writeResult transcriptText |
	
	"1. Get the active session"
	session := GbsLiveSessionTestSupport ensureSharedSession.
	session ifNil: [
		self skip: GbsLiveSessionTestSupport unavailableReason ].
	
	"2. Write to the remote transcript (returning true so we know it executed)"
	writeResult := session execute: 'Transcript show: ''TDD Hello''; cr. true'.
	self assert: writeResult equals: true. "FIXED: Standard SUnit assertion"
	
	"3. Fetch the transcript logs using your existing method"
	transcriptText := session fetchTranscriptLogs.
	
	"4. Assertions: Did the text come back across the FFI bridge?"
	self assert: transcriptText isString description: 'The fetched logs must be a String'.
	self assert: (transcriptText includesSubstring: 'TDD Hello') description: 'The Transcript text was missing or empty!'.
]
