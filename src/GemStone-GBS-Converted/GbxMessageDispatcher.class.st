Class {
	#name : #'GbxMessageDispatcher',
	#superclass : #'CstMessageDispatcher',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'commenting' }
GbxMessageDispatcher >> comment: aString withArguments: args
	"Comments are the lowest priority of all messages. They may
	 be displayed in a window status area, or may be written to a
	 log. They never interrupt processing. Write aString after starting
	 a new text line."

	| string |
	string := self printTimestamped: aString withArguments: args.
	self basicComment: string.

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString
	"Used for statistics gathering."

	self
		statusTag: aSymbol
		message: aString
		withArguments: #().

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3 with: arg4 with: arg5
	"Substitute all %1...%5 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (
			OrderedCollection new add: arg1; add: arg2; add: arg3; add: arg4; add: arg5; yourself
		).

{ #category : #'status tags' }
GbxMessageDispatcher >> traceLog: aBlock
	"Should be used when computing the log message is expensive enough to avoid when logging is turned off."

	GbsCallTracing isCallTracingActive ifFalse: [^self].
	aBlock value: self

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3 with: arg4
	"Substitute all %1...%4 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString withArguments: args
	"This method is the funnel point for call tracing.  If
	disabled, this method is a no-op."

	| string msg |
	GbsCallTracing isCallTracingActive ifFalse: [^self].
	msg := '[' , Processor activeProcess identityHash printString , ']'.
	aSymbol isNil ifFalse: [msg := msg , aSymbol , ' '].
	msg := msg , aString.
	string := self printTimestamped: msg withArguments: args.
	GbsCallTracing logMessage: string

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3
	"Substitute all %1...%4 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8
	"Substitute all %1...%8 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (
			OrderedCollection new add: arg1; add: arg2; add: arg3; add: arg4; add: arg5; add: arg6; add: arg7; add: arg8; yourself
		).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2
	"Substitute all %1...%4 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (Array with: arg1 with: arg2).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7
	"Substitute all %1...%7 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (
			OrderedCollection new add: arg1; add: arg2; add: arg3; add: arg4; add: arg5; add: arg6; add: arg7; yourself
		).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1
	"Substitute all %1...%4 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (Array with: arg1).

{ #category : #'status tags' }
GbxMessageDispatcher >> statusTag: aSymbol message: aString with: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6
	"Substitute all %1...%6 with the arguments passed."

	self
		statusTag: aSymbol
		message: aString
		withArguments: (
			OrderedCollection new add: arg1; add: arg2; add: arg3; add: arg4; add: arg5; add: arg6; yourself
		).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean
	"Report an assertion failure if aBoolean is true."

	self assert: aBoolean not

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean errorString: errorString
	"Report an assertion failure if aBoolean is true."

	self assert: aBoolean not errorString: errorString

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: #()

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean errorString: errorString
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: errorString
		withArguments: #()

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: #()

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString with: arg1
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString with: arg1 with: arg2
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString with: arg1
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString with: arg1 with: arg2 with: arg3
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString with: arg1 with: arg2 with: arg3 with: arg4
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean
	"Report an assertion failure if aBoolean is false."

	self assert: aBoolean errorString: 'Assertion failure'

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString with: arg1 with: arg2 with: arg3
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString with: arg1 with: arg2
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> deny: aBoolean failure: aString withArguments: args
	"Report an assertion failure if aBoolean is true."

	(aBoolean not or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: args

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString with: arg1 with: arg2 with: arg3 with: arg4
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4).

{ #category : #'assertion checks' }
GbxMessageDispatcher >> runAssertion: assertBlock forResult: expected message: failureString 
	"If assertions are not enabled, do nothing. 
	Otherwise, run the assertBlock, and report a failure if expected does not equal the result.
	It's usually more convenient to use the BlockClosure #gbxAssert* messages than to send 
	this message directly."

	self reportFailures 
		ifTrue: 
			[| result |
			result := assertBlock value.
			result = expected 
				ifFalse: 
					[self 
						failure: 'Assertion failure. %1 Expected %2 but received %3'
						with: failureString
						with: expected
						with: result]]

{ #category : #'assertion checks' }
GbxMessageDispatcher >> runGuarantee: guaranteeBlock forResult: expected message: failureString 
	"If assertions are not enabled, do nothing. 
	Otherwise, run the assertBlock, and report a failure if expected does not equal the result.
	It's usually more convenient to use the BlockClosure #gbxAssert* messages than to send 
	this message directly."

	| result |
	result := guaranteeBlock value.
	result = expected 
		ifFalse: 
			[self 
				error: 'Guarantee failed. %1 Expected %2 but received %3'
				with: failureString
				with: expected
				with: result]

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assert: aBoolean failure: aString withArguments: args
	"Report an assertion failure if aBoolean is false."

	(aBoolean or: [self reportFailures not]) ifTrue: [^self].
	self
		failure: aString
		withArguments: args

{ #category : #'assertion checks' }
GbxMessageDispatcher >> assertImmutable: anObject
	"Special purpose assertion. Passes if anObject is maked immutable.
	Stubs or forwarders should always be immutable, except during unpreemptible blocks."

	(self reportFailures and: [GbsConfiguration current autoMarkDirty or: [anObject gbxIsProxy]])
		ifTrue: [self assert: anObject isImmutable failure: 'Expected object to be marked immutable.']

{ #category : #'message handling' }
GbxMessageDispatcher >> basicRaise: errorSignal message: errorString

	^errorSignal raiseSignal: errorString

{ #category : #'message handling' }
GbxMessageDispatcher >> basicError: aString
	"Raise an error signal with aString for the notifier string."

	self
		statusTag: #gbsError
		message: aString.
	^self
			raise: GbsInterfaceError
			message: 'GBS Error - ', aString

{ #category : #'message handling' }
GbxMessageDispatcher >> basicWarn: aString
	"This is an important comment that is usually given to the user
	 for a response, but could also simply be reported. It indicates
	 that something undesireable has happened or could happen."

	^GbxDialog warn: aString.

{ #category : #'message handling' }
GbxMessageDispatcher >> reportFailures
	"Answer boolean whether there is an interest in reporting
	 failures."

	self gbxFixMe.	"After all assertions are converted to use #runAssertion:forResult: and friends,
				this method should just answer true."
	^GbsConfiguration current assertionChecks

{ #category : #'message handling' }
GbxMessageDispatcher >> basicFailure: errorString
	"An assertion test has failed. This is considered a low priority type of error
	 condition and execution is normally allowed to continue unless debugging."

	^self
		basicRaise: GbsAssertionError
		message: errorString

{ #category : #'printing' }
GbxMessageDispatcher >> printTimestamped: aString withArguments: anArrayOfArguments 
	"Answer a copy of aString with replacement of %1...%9
	 with the print representation of an items in
	 anArrayOfArguments. Ignores $% at end of aString."

	"	self new
			printTimestamped: '%1 is a %2 month for %3.'
			withArguments: #(August 'warm' Canada).
	"

	| wStream timeStamp |
	timeStamp := self handler formattedTimestamp.
	wStream := WriteStream 
				on: (aString species new: aString size + timeStamp size).
	self print: timeStamp on: wStream.
	self 
		print: aString
		on: wStream
		withArguments: anArrayOfArguments.
	^wStream contents

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString with: arg1
	"Substitute all %1...%4 with the arguments passed."

	^self
		raise: errorSignal
		message: aString
		withArguments: (Array with: arg1).

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString

	^self
		raise: errorSignal
		message: aString
		withArguments: #().

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString withArguments: args
	"Used for statistics gathering."

	| string |
	string := self print: aString withArguments: args.
	^self
		basicRaise: errorSignal
		message: string.

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString with: arg1 with: arg2 with: arg3 with: arg4
	"Substitute all %1...%4 with the arguments passed."

	^self
		raise: errorSignal
		message: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4).

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal

	^self
		raise: errorSignal
		message: errorSignal description
		withArguments: #().

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString with: arg1 with: arg2 with: arg3
	"Substitute all %1...%4 with the arguments passed."

	^self
		raise: errorSignal
		message: aString
		withArguments: (Array with: arg1 with: arg2 with: arg3).

{ #category : #'error raising' }
GbxMessageDispatcher >> raise: errorSignal message: aString with: arg1 with: arg2
	"Substitute all %1...%4 with the arguments passed."

	^self
		raise: errorSignal
		message: aString
		withArguments: (Array with: arg1 with: arg2).

