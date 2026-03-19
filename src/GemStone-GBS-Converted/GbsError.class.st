Class {
	#name : 'GbsError',
	#superclass : 'Object',
	#instVars : [
		'arguments',
		'category',
		'deferProcessing',
		'dontRaise',
		'errorText',
		'exceptionOop',
		'fatal',
		'gsResult',
		'number',
		'process',
		'reason',
		'session',
		'stepLevel',
		'terminateOnUnwind'
	],
	#classVars : [
		'ErrorNameToClassCompatibility',
		'GbsErrorNumbersToClasses',
		'GbsErrorNumbersToClasses6430'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private accessing' }
GbsError >> deferProcessing
[
	"This method returns the current value of deferProcessing.  If it's true,
	 it has the side affect of settinng it to false."

	| defer |
	session sessionCriticalNoSessionCheck: 
			[defer := deferProcessing.
			deferProcessing := false].
	^defer == true
]

{ #category : 'private accessing' }
GbsError >> arguments: anArray
[
	"Private"

	arguments := anArray
]

{ #category : 'private accessing' }
GbsError >> serverProcess: newVal
[
	"Private"

	^process := newVal
]

{ #category : 'private accessing' }
GbsError >> fatal: aBoolean
[
	"Private"

	fatal := aBoolean
]

{ #category : 'private accessing' }
GbsError >> errorText: aString causeOfDeath: aGbsErrorOrNil
[
	"Set the error string to aString.  If the given cause of death is
	 not nil, embellish the errorText with the cause of death."

	| receiverText |
	receiverText := self asExceptionClassDontCallGemStone name , ' - ' , aString.
	self errorText: (aGbsErrorOrNil isNil
				ifTrue: [receiverText]
				ifFalse: [aGbsErrorOrNil messageText , ', probable cause of: ' , receiverText]).
	self reason: ''	"Normally set by the GCI interface when it creates an error."
]

{ #category : 'private accessing' }
GbsError >> category: aGemStoneObject
[
	"Private"

	category := aGemStoneObject
]

{ #category : 'private accessing' }
GbsError >> deferProcessing: defer
[

	"If deferProcessing is true on a session's causeOfDeath GbsError, that
	 error will be reraised.  This mechanism prevents the event poller thread
	 from consuming causeOfDeath errors."

	deferProcessing := defer
]

{ #category : 'private accessing' }
GbsError >> session: aGSSession
[
	"Private"

	session := aGSSession.
	^self
]

{ #category : 'private accessing' }
GbsError >> number: anInteger
[
	"Private"

	number := anInteger.
	^self
]

{ #category : 'accessing' }
GbsError >> stackDepth
[

	^process = self session oopNil ifFalse: [process performOnGsServer: #stackDepth] ifTrue: [0]
]

{ #category : 'accessing' }
GbsError >> number
[

	^number
]

{ #category : 'accessing' }
GbsError >> augmentErrorTextForCompilerError
[
	"rather long method which adds the compiler error 
	text to help the user. Text is abbreviated if necessary"
	"some server compiler errors don't seem to come back with 
	compilerErrorText, such as GbsStDBErrCodeGenLogic. 
	In that case we just insert some nice text to help the user identify the
	problem"

	| methodSrc newSourceStream max compilerErrorMessage sourceErrorOffset displayedSourceStart displayedSourceEnd prefixString suffixString |
	self isCompilerError ifFalse: [^self].
	methodSrc := self compilerErrorSource.
	compilerErrorMessage := self compilerErrorText.
	compilerErrorMessage == nil ifTrue: [compilerErrorMessage := 'error occurred here'].
	methodSrc notNil
		ifTrue: 
			[max := 80.
			sourceErrorOffset := self compilerErrorOffset.
			displayedSourceStart := sourceErrorOffset - (max // 2) max: 1.
			displayedSourceEnd := displayedSourceStart + max min: methodSrc size.
			prefixString := displayedSourceStart = 1 ifTrue: [''] ifFalse: ['...'].
			suffixString := displayedSourceEnd = methodSrc size ifTrue: [''] ifFalse: ['...'].
			newSourceStream := WriteStream on: (String new: max * 2).
			newSourceStream
				cr;
				nextPutAll: prefixString;
				cr;
				nextPutAll: (methodSrc copyFrom: displayedSourceStart to: sourceErrorOffset - 1);
				cr;
				nextPutAll: '>>>';
				nextPutAll: compilerErrorMessage;
				nextPutAll: '>>> ';
				nextPutAll: (methodSrc copyFrom: sourceErrorOffset to: displayedSourceEnd);
				cr;
				nextPutAll: suffixString.
			self errorText: newSourceStream contents causeOfDeath: self causeOfDeath]
]

{ #category : 'accessing' }
GbsError >> errorText: aString
[

	errorText := aString
]

{ #category : 'accessing' }
GbsError >> exceptionOop: aDelegate
[

	exceptionOop := aDelegate
]

{ #category : 'accessing' }
GbsError >> arguments
[
	^arguments
]

{ #category : 'accessing' }
GbsError >> category
[

	^category
]

{ #category : 'accessing' }
GbsError >> causeOfDeath
[

	"If this GbsError's session has a cause of death, return it - it may
	 be the cause of this GbsError."

	^session isNil
		ifTrue: [ nil ]
		ifFalse: [ session causeOfDeath ]
]

{ #category : 'accessing' }
GbsError >> fatal
[

	^fatal
]

{ #category : 'accessing' }
GbsError >> gsResult: anObject
[

	"This is used by the debugger for communicating the result of completing
	 GemStone execution to be returned by the signal processing method"
	gsResult := anObject
]

{ #category : 'accessing' }
GbsError >> compilerErrorNumber
[
	"GemStone compiler errors are reported differently than other errors.  Rather than having a single error and zero or more arguments, all compiler errors are reported with number 1001 and have a single argument that is an error descriptor object.  Each error descriptor is an array of three elements:  1) an error number (numbered from 002 to 999),  2) an offset into the source code string pointing to where the error was detected, and 3) message text describing the error."

	| errorDescriptor |
	errorDescriptor := arguments at: 1.
	^errorDescriptor session evaluate: '(self at: 1) at: 1' context: errorDescriptor
]

{ #category : 'accessing' }
GbsError >> compilerErrorOffset
[
	"GemStone compiler errors are reported differently than other errors.  Rather than having a single error and zero or more arguments, all compiler errors are reported with number 1 and have a single argument that is an error descriptor object.  Each error descriptor is an array of three elements:  1) an error number (numbered from 002 to 999),  2) an offset into the source code string pointing to where the error was detected, and 3) message text describing the error."

	self gbxFixMe.	"Should have a client ErrorDescription class rather than all these round trips."
	^(((arguments at: 1) fetchOOPAt: 1) fetchOOPAt: 2) asLocalObject
]

{ #category : 'accessing' }
GbsError >> session
[

	"Return the GbsSession that this error occurred in"

	session isNil
		ifTrue: [ ^GBSM currentSession ]
		ifFalse: [ ^session ]
]

{ #category : 'accessing' }
GbsError >> gsReturnVal
[
	"Answer the delegate for the object that should replace top of stack if this error is resumed.
	If the top of stack should not be replaced, answer OOP_ILLEGAL.
	Each error should only replace the top of stack once (in debugger stepping, the same error can be 
	continued more than once, but should only affect the stack the first time) 
	so reset gsResult to OOP_ILLEGAL"

	| result |
	result := gsResult.
	gsResult := GbxKernelPomOop oopIllegal asGSObjectInSession: self session.
	^result == nil ifTrue: [gsResult] ifFalse: [result]
]

{ #category : 'accessing' }
GbsError >> compilerErrorSource
[
	"Compiler errors sometimes report the source code causing the error.  If the receiver contains this information, return it as a local string.  Otherwise, return nil."

	self gbxFixMe.	"Should have a client ErrorDescription class rather than all these round trips."
	arguments size >= 2 
		ifTrue: [^(arguments at: 2) asLocalObject]
		ifFalse: [^nil]
]

{ #category : 'accessing' }
GbsError >> compilerErrorText
[
	"GemStone compiler errors are reported differently than other errors.  Rather than having a single error and zero or more arguments, all compiler errors are reported with number 1 and have a single argument that is an error descriptor object.  Each error descriptor is an array of three elements:  1) an error number (numbered from 1002 to 1999),  2) an offset into the source code string pointing to where the error was detected, and 3) message text describing the error."

	self gbxFixMe.	"Should have a client ErrorDescription class rather than all these round trips."
	^(((arguments at: 1) fetchOOPAt: 1) fetchOOPAt: 3) asLocalObject
]

{ #category : 'accessing' }
GbsError >> reason
[
	^reason ifNil: ['']
]

{ #category : 'accessing' }
GbsError >> reason: aString
[

	reason := aString
]

{ #category : 'accessing' }
GbsError >> continuable
[

	"With the exception of the following errors, an error that is not fatal is continuable:  rtErrStackLimit, bkupErrRestoreSuccessful, abortErrFinishedObjAudit."

	| ex |
	ex := self asExceptionClass.
	^(self isFatalError not) &
		(ex ~~ (GbsError signalFor: #rtErrStackLimit)) &
		(ex ~~ (GbsError signalFor: #bkupErrRestoreSuccessful)) &
		(ex ~~ (GbsError signalFor: #abortErrFinishedObjAudit))
]

{ #category : 'accessing' }
GbsError >> serverProcess
[

	^process
]

{ #category : 'accessing' }
GbsError >> dontRaise: anObject
[
	dontRaise := anObject
]

{ #category : 'accessing' }
GbsError >> errorSymbol
[

	"Return the symbolic name associated with this error"
	| errorSymbol |
	errorSymbol := self asExceptionClass name.
	"Strip off Gbs"
	errorSymbol := errorSymbol copyFrom: 4 to: errorSymbol size.
	"Lowercase the first letter"
	errorSymbol at: 1 put: ((errorSymbol at: 1) asLowercase).
	^errorSymbol asSymbol
]

{ #category : 'accessing' }
GbsError >> stepLevel
[
	^stepLevel
]

{ #category : 'accessing' }
GbsError >> messageText
[

	^self reason isEmpty
		ifTrue: [self errorText]
		ifFalse: [self errorText , ' ' , self reason].
]

{ #category : 'accessing' }
GbsError >> errorText
[
	"Should use #messageText to get all the information, error text and reason."

	^errorText ifNil: ['']
]

{ #category : 'testing' }
GbsError >> gbxIsGSError
[

	"Coerce instances of GSError to true and everything else to false"
	^true
]

{ #category : 'testing' }
GbsError >> isBreakPointLike
[
	^number == 6002 "rtErrStep"
		or: [number == 6006	"rtErrStackBreakpoint"
		or: [number == 6005	"rtErrCodeBreakpoint"
		or: [number == 6001	"rtErrPause"]]]
]

{ #category : 'testing' }
GbsError >> isRealError
[
	"If this instance was created using lastError, but the previous GemStone call did not cause an error, then this instance does not represent an actual error.  In this case, this method returns false; otherwise, it returns true."

	^category isGSObject 
		and: [category ~= self session oopNil and: [number ~= 0]]
]

{ #category : 'testing' }
GbsError >> isAsyncAbortError
[

	^number = 3007
]

{ #category : 'testing' }
GbsError >> isInterpreterError
[

	^(category = OGemStoneErrorCategory) & (number//1000 == 2)
]

{ #category : 'testing' }
GbsError >> isAbortingError
[

	^(category = OGemStoneErrorCategory) & (number//1000 == 3)
]

{ #category : 'testing' }
GbsError >> isFatalError
[
	"For an error from GemStone, the fatal field of a GemStone error is true whenever the error number is in the 4000 range.  We also want to consider fatal errors for which the fatal field has not been initialized. This includes system errors indicating problems making a GCI call.
	We also consider as fatal error 2423, RtErrGciTravNotLicensed, License does not allow Gci Traversal operations. This is not fatal from the server's point of view, but it is fatal to GBS since GBS relies on traversal so heavily that if not fatal would try to do traversal operations in attempting to maintain synchronization after the error, causing infinite recursion."

	^fatal ~~ false or: [number == 2423]
]

{ #category : 'testing' }
GbsError >> isGemStoneError
[
	"Return true if this error orignated in GemStone.  Otherwise, return false (which could indicate a primitive failure)."

	^category isGSObject and: [number ~= 0]
]

{ #category : 'testing' }
GbsError >> hasValidServerProcess
[
	"True if I have a valid GemStone context"

	"if the system tries to terminate a server process, but the session for this error is no longer valid, 
	then doing a 'process isSpecial' will cause #session to be sent to the process delegate which
	will in turn generate a bad session id error if the session is no longer registered. Then you will 
	return the wrong type of error. So do a check with the session manager first to see if we should even bother checking the process.

	GbtErrorTest>>multiThreadedErrorsEventPollerConsumesError exposes this problem"

	^self hasServerProcess and: 
			[process sessionIsLoggedIn
			"The following commented out for performance optimization"
			"and: [ process remoteClass = OGsProcess
		and: [ (process privatePerform: #stackDepth) asLocalInteger >= 1 ]] "]
]

{ #category : 'testing' }
GbsError >> isEventError
[

	^(category = OGemStoneErrorCategory) & (number//1000 == 6)
]

{ #category : 'testing' }
GbsError >> hasServerProcess
[
	"True if I have a GemStone context that appears good."

	session isNil ifTrue: [^false].	"My session will be nil if I represent, for example, a bad handle error"
	session hasValidSessionId ifFalse: [^false].
	^process isGSObject and: [process isSpecial not]
]

{ #category : 'testing' }
GbsError >> isCompilerError
[
	fatal == true ifTrue: [^false].	"Short circuit to avoid problem reporting login failure"
	^number // 1000 == 1 and: [category = OGemStoneErrorCategory]
]

{ #category : 'private debugger support' }
GbsError >> stepLevel: anIntegerOrNil 
[
	"When server execution that stopped with the receiver is continued, 
	if nil continue, if an integer step in that level counting from the top 
	of the GsProcess stack."

	stepLevel := anIntegerOrNil
]

{ #category : 'initialize-release' }
GbsError >> initialize
[
	terminateOnUnwind := true
]

{ #category : 'printing' }
GbsError >> printOn: aStream
[

	aStream
		nextPutAll: self class printString;
		space;
		nextPutAll: self messageText printString;
		cr;
		nextPutAll: 'gsResult: '.
	gsResult printOn: aStream.
	aStream
		cr;
		nextPutAll: 'stepLevel: '.
	stepLevel printOn: aStream.
	aStream
		cr;
		nextPutAll: 'number: '.
	number printOn: aStream
]

{ #category : 'private error processing' }
GbsError >> processGemStoneError
[
	"Private.  Raise a signal representing this GemStoneError"

	"Process any exception handlers for this error"

	^self processHandlers

	"If we return a value, either no exception was thrown or we're resuming."
]

{ #category : 'private error processing' }
GbsError >> asSignal
[
	"Private and deprecated.  A GemStone error is no longer represented by a signal,
	 but is represented by an Exception."

	GbsConfiguration 
		deprecated: 'GbsSession>>asSignal deprecated March, 2006. A GemStone error is no longer represented by a signal, 	 but is represented by an Exception. Send #asExceptionClass directly'.
	^self asExceptionClass
]

{ #category : 'private error processing' }
GbsError >> terminateGsProcess
[
	"If I have a valid GsProcess, terminate it.

	If we get an error on terminate, set the terminateOnUnwind
	flag to false then proceed. Proceeding will try to unwind the 
	stack again,  which we will reset the flag to true and not
	try to terminate, then continue unwinding the server
	call. At least that's the theory.  "

	terminateOnUnwind
		ifTrue: 
			[self hasValidServerProcess
				ifTrue: 
					[[self serverProcess remotePerform: #terminate]
						on: Error
						do: 
							[:ex |
							terminateOnUnwind := false.
							ex return]]]
		ifFalse: [terminateOnUnwind := true]
]

{ #category : 'private error processing' }
GbsError >> asExceptionClassDontCallGemStone
[
	"Private.  Answer the exception class representing this GemStone error.  Don't
	 try to call GemStone - so, if this is a compiler error, just answer the generic
	 compiler error class rather than calling GemStone to determine the compiler
	 error number."

	self class ensureErrorMapsInitialized.
	^GbsErrorNumbersToClasses at: number
		ifAbsent: [GbsGemStoneError]
]

{ #category : 'private error processing' }
GbsError >> replicateException
[

	^exceptionOop asLocalObject
]

{ #category : 'private error processing' }
GbsError >> asExceptionClass
[
	"Private.  Answer the exception class representing this GemStone error.  Note:  If
	 this is a compiler error, the specific error number must be fetched from GemStone"

	| errNum |
	self class ensureErrorMapsInitialized.
	errNum := number.
	self isCompilerError ifTrue: [errNum := self compilerErrorNumber].
	^GbsErrorNumbersToClasses at: errNum
		ifAbsent: [GbsGemStoneError]
]

{ #category : 'private error processing' }
GbsError >> raiseException
[
	"Raise the appropriate exception for my kind of error.
	If the exception handler resumes, save the result value for 
	continuing server execution and answer myself.
	Substitute the cause of death if it exists and has been deferred."

	| result error exception |
	self gbsMessenger
		statusTag: #gemStoneError
		message: '(s%1) GS Server Error - %2 - %3'
		with: self session sessionId
		with: self errorSymbol
		with: self messageText.
	exception := self asException.
	error := exception originator.	"Usually self, but could be cause of death instead."
	result := exception raiseSignal.
	"If we get here, the exception has been resumed."
	(exception isResumable and: [result isNil not])
		ifTrue: [error gsResult: (result putInGSSession: session)].
	^error
]

{ #category : 'private error processing' }
GbsError >> asException
[

	| cause error exception |
	cause := self causeOfDeath.
	error := cause isNil ifTrue: [self] ifFalse: [cause deferProcessing ifTrue: [cause] ifFalse: [self]].
	error augmentErrorTextForCompilerError.
	(cause == nil and: [session shouldReplicateExceptions])
		ifTrue: 
			["replicate the exception"
			exception := error replicateException]
		ifFalse: 
			["look up by number"
			exception := error asExceptionClass new.
			exception messageText: 'GS Server Error - ' , error messageText].
	exception originator: error.
	^exception
]

{ #category : 'private error processing' }
GbsError >> process
[

	"Private.  Raise a signal representing this GemStoneError"
	^self processVerifyArgs: [ true ]
]

{ #category : 'private error processing' }
GbsError >> processVerifyArgs: verifyArgsBlock
[
	"Raise a signal representing this GemStoneError"

	self isGemStoneError ifTrue: [^self processGemStoneError].

	"Error didn't originate in GemStone - run verifyArgsBlock"
	^verifyArgsBlock value
		ifTrue:
			["Apparently, the error isn't due to bad arguments. Primitive failure (SystemError)?"
			number isError
				ifTrue:
					[self gbsMessenger
						error: 'GCI call failed with error: %1 and parameter: %2'
						with: number name
						with: number parameter]
				ifFalse:
					[self gbsMessenger
						error: 'GemBuilder encountered an unknown error']]
]

{ #category : 'private error processing' }
GbsError >> processHandlers
[
	"Private.  If the session has an event handler for this signal, it will be processed
	 here.  An exception will also be raised here, if there is either no event handler, or
	if the event handler specifies that an exception be raised.
	If an exception is raised and not resumed, terminate the GemStone process
	as we are terminated.
	Otherwise, the GemStone process is probably going to be continued -- 
	answer the result of client execution to be returned to GemStone.
	If no exception is raised, answer OIllegal --  either no value is to be returned to 
	GemStone or it is to be communicated through gsResult.
	If an exception is raised and resumed, answer the resume value."

	dontRaise == true 
		ifTrue: 
			[" this error has been dropped from the stack by the user "

			^self].
	^self session processEventHandlerFor: self
]

{ #category : 'private-class initialization' }
GbsError class >> initErrorNumbersDict: dict selector: selector
[
	"Initialize the given dictionary that maps GemStone error numbers to client ANSI exception classes.
	Access the error numbers using the given version-specific selector, either #gemStoneErrorNumber32, #gemStoneErrorNumber64, or #gemStoneErrorNumber6430"

	| errorLog |
	errorLog := WriteStream on: String new.
	self serverErrorClasses do: 
			[:cls |
			| response nums |
			response := cls perform: selector.
			response ~~ nil
				ifTrue: 
					[nums := (response isKindOf: Array)
								ifTrue: [response]
								ifFalse: [Array with: response].
					nums do: 
							[:num |
							(dict includesKey: num)
								ifTrue: 
									[errorLog
										cr;
										nextPutAll: 'Error number conflict: ';
										nextPutAll: num printString;
										nextPutAll: ' is mapped to ';
										nextPutAll: (dict at: num) printString;
										nextPutAll: ' and ';
										nextPutAll: cls printString].	"work around known error symbol conflict in 3.2 server"
							dict at: num put: cls]]].
	errorLog isEmpty
		ifFalse: 
			[| errorMsg |
			errorMsg := errorLog contents.
			Transcript
				cr;
				show: errorMsg.
			self gbsMessenger
				error: 'Error number conflicts - see Transcript. Proceed to complete the udpate.']
]

{ #category : 'private-class initialization' }
GbsError class >> initErrorNumbersToClasses
[
	"Initialize the dictionaries that map GemStone error numbers to client ANSI exception classes."

	GbsErrorNumbersToClasses6430 := IdentityDictionary new.
	self initErrorNumbersDict: GbsErrorNumbersToClasses6430
		selector: #gemStoneErrorNumber6430.
	GbsErrorNumbersToClasses := GbsErrorNumbersToClasses6430
	"If a 32-bit or 64-bit 2.x library is loaded, it will be assigned
	at library load time. GbsErrorNumbersToClasses is to have some error
	dict when no library has yet been loaded."
]

{ #category : 'private-class initialization' }
GbsError class >> initSignals
[
	"GbsError initialize"

	"VisualWorks compatibility - notifierString: doesn't exist in Pharo"
	"GbsUnsupportedFloatError
		notifierString: 'Attempt to replicate a GemStone float that isn''t supported in Smalltalk'.
	GbsClassGenerationError notifierString: 'Class creation error'.
	GbsConnectorError notifierString: 'Connection error'.
	GbsNotCachedError notifierString: 'Not cached'.
	GbsBlockReplicationError
		notifierString: 'Unable to replicate a BlockClosure'.
	GbsAssertionError notifierString: 'A GBS assertion check has failed'"
]

{ #category : 'private-class initialization' }
GbsError class >> ensureErrorMapsInitialized
[

	(GbsErrorNumbersToClasses isNil or: [ErrorNameToClassCompatibility isNil])
		ifTrue: [self initialize]
]

{ #category : 'private-class initialization' }
GbsError class >> initializeErrorNameToClassCompatibility
[

	"For backward compatibility - map the old names for error categories to the new class names"

	ErrorNameToClassCompatibility := IdentityDictionary new.
	ErrorNameToClassCompatibility
		at: #fatalErrorSignal put: GbsFatalError;
		at: #abortingErrorSignal put: GbsAbortingError;
		at: #compilerErrorSignal put: GbsCompilerError;
		at: #eventErrorSignal put: GbsEventError;
		at: #interpreterErrorSignal put: GbsInterpreterError;
		at: #gsiError put: GbsInterfaceError;
		at: #gsiAssertionFail put: GbsAssertionError;
		at: #gsiBlockReplicationFailed put: GbsBlockReplicationError;
		at: #gsiUnsupportedFloat put: GbsUnsupportedFloatError
]

{ #category : 'class initialization' }
GbsError class >> initialize
[

	"GbsError initialize"

	self initSignals.
	self initErrorNumbersToClasses.
	self initializeErrorNameToClassCompatibility
]

{ #category : 'private' }
GbsError class >> classNameFromErrorSymbol: errorSym
[

	| classname |
	classname := errorSym asString.
	classname at: 1 put: (classname at: 1) asUppercase.
	classname := 'Gbs' , classname.
	^classname asSymbol
]

{ #category : 'private' }
GbsError class >> gsiError: aString
[
	"This method is obsolete."

	^self gbsMessenger
		error: aString.
]

{ #category : 'private' }
GbsError class >> forException: exception errorText: aString session: aGbsSession 
[
	"Return a new GbsError corresponding to the given exception class.  The argument exception must be an exception class corresponding to a GemStone server error."

	"Note that there are a handful of exception classes for which gemStoneErrorNumber returns an array of numbers.  Martin & Dave decided it probably wasn't necessary to take the step of trying to determine which error number was correct for the given server we're currently attached to - only 4 errors fall into this scenario right now, and this method is the only runtime path affected, and it's currently only used for GbsGciErrBadSessionId, which has a single error number across server products/versions. This won't work if we ever need to use this for errors with different numbers
in 32 and 64 bit."

	| err |
	err := self number: exception gemStoneErrorNumber6430 session: aGbsSession.
	err errorText: aString
		causeOfDeath: (aGbsSession == nil 
				ifTrue: [nil]
				ifFalse: [aGbsSession causeOfDeath]).
	err category: (SpecialGemStoneObjects at: 'OGemStoneErrorCategory').
	err serverProcess: (aGbsSession == nil 
				ifTrue: [nil]
				ifFalse: [aGbsSession oopNil]).
	^err
]

{ #category : 'private' }
GbsError class >> serverErrorClasses
[
	"Return a new collection of client classes representing GemStone errors"
	
	| existingClasses |
	existingClasses := GbsGemStoneError allSubclasses
		, GbxAbstractControlInterrupt allSubclasses
		, GbxAbstractContextEmergencyError allSubclasses.
	existingClasses removeAll: GbsGemStoneError subclasses.	"The immediate subclasses are abstract."
	^existingClasses
]

{ #category : 'private' }
GbsError class >> selectErrorMap
[

	self ensureErrorMapsInitialized.
	GbsErrorNumbersToClasses := GbsErrorNumbersToClasses6430
]

{ #category : 'private' }
GbsError class >> closestSignalTo: targetSignal from: sourceSignals
[

	"Given the collection of Signals, sourceSignals, return one
	 of its elements which accepts targetSignal.  If more than
	 one of sourceSignals accepts targetSignal, select the most
	 specific.  If none accept, return nil.  For example,

	 GbsError
		closestSignalTo: (GbsError signalFor: #objErrOopNotAllocated)
		from: (Array
			with: GbsError hostErrorSignal
			with: (GbsError signalFor: #objErrOopNotAllocated)
			with: GbsError gsiErrorSignal
			with: GbsError hostErrorSignal)

	 will return (GbsError signalFor: #objErrOopNotAllocated), since
	 it exactly matches the target, even though the other two also
	 accept the target."

	| best |
	best := nil.
	sourceSignals do: [ :sig |
		(sig accepts: targetSignal) ifTrue: [
			(best isNil or: [ best accepts: sig ]) ifTrue: [ best := sig ].
		].
	].
	^best

	"Note: The old #accepts: had to be used instead of ANSI #handles: because
		 targetSignal is a signal (not an exception) and #handles: sends #creator."
]

{ #category : 'private' }
GbsError class >> raiseBadSessionIdFor: aGbsSession errorText: errorText
[

	"Create a new GbsError for #gciErrBadSessionId, associated with the
	presumably dead aGbsSession, and process it."

	| err |
	err := self 
		forException: GbsGciErrBadSessionId
		errorText: errorText
		session: aGbsSession.
	^err process
]

{ #category : 'private' }
GbsError class >> raiseBadSessionIdFor: aGbsSession
[

	"Create a new GbsError for #gciErrBadSessionId, associated with the
	presumably dead aGbsSession, and process it."

	^self
		raiseBadSessionIdFor: aGbsSession
		errorText: 'This session is not logged in to GemStone'
]

{ #category : 'signal constants' }
GbsError class >> defineErrorNumber: number class: errorClass
[

	"Register the given user-defined server error number with the given Smalltalk error class.  After using this method, subsequent occurrences of the given error number during GemStone execution will raise the given signal in Smalltalk."

	self ensureErrorMapsInitialized.
	GbsErrorNumbersToClasses at: number put: errorClass
]

{ #category : 'signal constants' }
GbsError class >> signalFor: anErrorSymbol
[
	"Converts a GemStone error symbol to a client side error class"
	"e.g. GbsError signalFor: #rtErrDoesNotUnderstand"

	^self exceptionClassFor: anErrorSymbol
]

{ #category : 'signal constants' }
GbsError class >> exceptionClassFor: anErrorSymbol
[
	"Converts a GemStone error symbol to a client side error class"
	"e.g. GbsError signalFor: #rtErrDoesNotUnderstand"

	| className |
	self ensureErrorMapsInitialized.
	className := self classNameFromErrorSymbol: anErrorSymbol.
	^Smalltalk at: className
		ifAbsent: 
			[ErrorNameToClassCompatibility at: anErrorSymbol
				ifAbsent: 
					[self gbsMessenger error: 'Unknown error symbol - %1' with: anErrorSymbol]]
]

{ #category : 'signal constants' }
GbsError class >> errorSignal
[

	"Signal indicating a GemStone (back end) error"

	^GbsGemStoneError
]

{ #category : 'private-argument verification' }
GbsError class >> verifyBytes: anObject
[

	"Returns true if anObject is stored as bytes.  Otherwise, a signal a GBS error."
	"GbsError verifyBytes: Array new"
	"GbsError verifyBytes: #a->#b"
	"GbsError verifyBytes: 'abc'"
	"GbsError verifyBytes: #[ 1 2 3 4 ]"

	(anObject class isBits)
		ifTrue: [ ^true ]
		ifFalse: [
			self gbsMessenger error: '%1 was not of expected byte implementation' with: anObject.
			^false
		]
]

{ #category : 'private-argument verification' }
GbsError class >> verify: anObject is: aClass or: anotherClass
[

	"Returns true if anObject is a kind of aClass or anotherClass.  Otherwise, a signal a GBS error."
	"GbsError verify: 'abc' is: Collection or: Stream"
	"GbsError verify: Object new is: Symbol or: Bag"

	((anObject isKindOf: aClass) or: [ anObject isKindOf: anotherClass ])
		ifTrue: [ ^true ]
		ifFalse: [
			self gbsMessenger error: '%1 was not of expected class %2 or %3' with: anObject with: aClass with: anotherClass.
			^false
		]
]

{ #category : 'private-argument verification' }
GbsError class >> verify: anObject is: aCollectionClass of: aClass
[

	"Returns true if anObject is a kind of aCollectionClass, and each of its elements is a kind of aClass.  Otherwise, a signal a GBS error."
	"GbsError verify: #( 1 2 3 ) is: Collection of: Integer"
	"GbsError verify: $x is: Bag of: Stream"
	"GbsError verify: #( 1 #x 3 ) is: Collection of: Number"

	(self verify: anObject is: aCollectionClass)
		ifTrue: [
			(anObject reject: [ :element | self verify: element is: aClass ]) isEmpty
				ifTrue: [ ^true ]].
	^false
]

{ #category : 'private-argument verification' }
GbsError class >> verify: anObject is: aClass
[

	"Returns true if anObject is a kind of aClass.  Otherwise, a signal a GBS error."
	"GbsError verify: 'abc' is: Collection"
	"GbsError verify: Object new is: Symbol"

	(anObject isKindOf: aClass)
		ifTrue: [ ^true ]
		ifFalse: [
			self gbsMessenger error: '%1 was not of expected class %2' with: anObject with: aClass.
			^false
		]
]

{ #category : 'private-argument verification' }
GbsError class >> primUnpolledResultOrError: resultOrError verifyArgs: verifyArgsBlock session: session
[

	"Private - This is a fix for BUG18642. This method is identical to the
	 #primResultOrError:verifyArgs:session: method except that it doesn't
	 poll for signal. It was felt that the poll won't be missed because
	 operations which call getFreeOops: will make at least one more
	 GemStone call (a storeTraversal call in this example), which will go
	 through the version of #primResultOrError... that does make the pollForSignal call"

	resultOrError gbxIsGSError
		ifTrue: [^resultOrError processVerifyArgs: verifyArgsBlock].
	^resultOrError
]

{ #category : 'private-argument verification' }
GbsError class >> verifyBytes: anObject or: aCollectionClass of: aClass
[

	"Returns true if anObject is bytes, or a collection whose elements are each a kind of aClass.  Otherwise, a signal a GBS error."
	"GbsError verifyBytes: 'abc' or: Array of: Object"
	"GbsError verifyBytes: (Array with: Object new) or: Array of: Object"
	"GbsError verifyBytes: Object new or: Array of: Object"

	(anObject class isBits)
		ifTrue: [ ^true ]
		ifFalse: [ ^self verify: anObject is: aCollectionClass of: aClass ]
]

{ #category : 'private-argument verification' }
GbsError class >> primResultOrError: resultOrError verifyArgs: verifyArgsBlock session: session 
[
	"If resultOrError is an error, process it.  If it is a result, return it.
	 Before returning it, however, call GciPollForSignal
	 in linked sessions.  This is a fix for bug 12840."

	resultOrError gbxIsGSError 
		ifTrue: [^resultOrError processVerifyArgs: verifyArgsBlock].
	session isLinked 
		ifTrue: 
			[| event |
			
			[(event := session 
						serverInterfaceDo: [:if | if pollForSignalFor: session deferFatalErrors: false]) 
					gbxIsGSError] 
					whileTrue: [event process]].
	^resultOrError
]

{ #category : 'obsolete' }
GbsError class >> gsiErrorSignal
[
	"Used to signal errors that occur at the GBS level, as opposed to GbsError>>errorSignal, which is used to signal GemStone errors at the repository level."

	GbsConfiguration 
		deprecated: 'GbsError class>>#gsiErrorSignal deprecated January 2008. Reference GbsInterfaceError directly'.
	^GbsInterfaceError
]

{ #category : 'instance creation' }
GbsError class >> new
[
	^super new initialize
]

{ #category : 'instance creation' }
GbsError class >> number: anInteger
[

	^self new number: anInteger	"Private"
]

{ #category : 'instance creation' }
GbsError class >> number: anInteger session: aGSSession
[

	^self new number: anInteger; session: aGSSession
]
