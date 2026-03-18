Class {
	#name : 'GbsCallTracing',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
		'Logger',
		'mutex',
		'TraceNestingLevel'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsCallTracing class >> isCallTracingActive
[

	^Logger notNil
]

{ #category : 'logging to memory' }
GbsCallTracing class >> startCallTracingToMemoryMegabytes: aNumber fileName: filename
[
	"Turn on call tracing to record the traces in a ring buffer of the specified size.
	 The contents of the ring buffer can be written to the specified file on request.
	 Answer the resulting logger."

	mutex critical: 
			[self privateStopCallTracing.
			Logger := GbxMemoryLogger usingBufferOfMegabytes: aNumber
						andFileNamed: filename].
	^Logger
]

{ #category : 'logging to memory' }
GbsCallTracing class >> writeToFile
[

	self isCallTracingActive ifFalse: [^self].
	Logger writeToFile
]

{ #category : 'logging to memory' }
GbsCallTracing class >> startCallTracingToMemoryMegabytes: aNumber
[
	"Turn on call tracing to record the traces in a ring buffer of the specified size.
	 The contents of the ring buffer can be written to a default file on request.
	 Answer the resulting logger."

	^self startCallTracingToMemoryMegabytes: aNumber
		fileName: self defaultLogFileName
]

{ #category : 'class initialization' }
GbsCallTracing class >> initialize
[
	"GbsCallTracing initialize"

	mutex := GbxRecursionLock forMutualExclusion.
	TraceNestingLevel := 0.
]

{ #category : 'logging to file' }
GbsCallTracing class >> traceFileNameIfNone: aBlock
[

	^self isCallTracingActive
		ifTrue: [Logger filename]
		ifFalse: [aBlock value].
]

{ #category : 'logging to file' }
GbsCallTracing class >> startCallTracingToFileNamed: filename
[
	"Turn on call tracing to record the traces to the specified file.
	 Answer the resulting logger."

	mutex critical: 
			[self privateStopCallTracing.
			Logger := GbxFileLogger usingFileNamed: filename.
			Logger startLogging].
	^Logger
]

{ #category : 'logging to file' }
GbsCallTracing class >> traceToFilename: aString during: aBlock
[

	"Example usage (from diagnosing a GC problem in a test):
	GbsCallTracing
			traceToFilename: (self tester 
					filenameForPurpose: 'impSortedCollection_bugs_8768_8776_', 
						(self tester testSelections areAllTestsSelected
							ifTrue: ['all']
							ifFalse: ['subset'])
					extension: '.log')
			during: [
				stObj := gsObj asLocalObjectCopy.
			].
	"

	| oldName |
	oldName := self traceFileNameIfNone: [].
	[self startCallTracingToFileNamed: aString.
	self traceFor: aBlock]
		ensure: 
			[oldName isNil
				ifTrue: [self stopCallTracing]
				ifFalse: [self startCallTracingToFileNamed: oldName]].
]

{ #category : 'logging to file' }
GbsCallTracing class >> traceFor: aBlock withTiming: doTiming startMessage: string1 endMessage: string2
[
	"Enable GBS & GCI tracing during the execution of aBlock (a zero-argument block).
	 Wrap the trace output with banner strings before and after.  Invocations of can be nested;
	 the banners will keep track of the nesting and enabling of logging will be controlled properly.
	 If doTiming is true, the time to run the block is printed in the trace.
	 If string1 is non-nil, print it to the tracefile just afer the block entry banner;
	 if string2 is non-nil, print it to the tracefile just before the block exit banner.
	 Answer the result of evaluating the block."

	| result start time |
	(TraceNestingLevel = 0)
		ifTrue: [self logMessage: '** Beginning trace block **']
		ifFalse: [ self logMessage: '** Beginning trace block at level ' , TraceNestingLevel printString, ' **'].
	TraceNestingLevel := TraceNestingLevel + 1.
	string1 isNil ifFalse: [ self logMessage: string1 ].
	doTiming ifTrue: [ start := Time millisecondClockValue ].
	result := [aBlock value]
		on: Error
		do: [ :ex |
			TraceNestingLevel := 0.
			self logMessage: 'Exception occurred while tracing.'.
			self logMessage: (ex messageText).
			ex pass.
		].
	TraceNestingLevel = 0	"Exception occurred in block evaluation."
		ifFalse: [ TraceNestingLevel := TraceNestingLevel - 1.
				string2 isNil ifFalse: [ self logMessage: string2 ].
				doTiming ifTrue: [ time := Time millisecondClockValue - start. ].
				(TraceNestingLevel = 0)
					ifTrue:
						[self logMessage: '** Ending trace block ' ,
							(doTiming
								ifTrue: [ ' - total time: ' , time printString , ' milliseconds. **' ]
							  	ifFalse: [ '**' ])]
					ifFalse:
						[self logMessage: '** Ending trace block at level ' , TraceNestingLevel printString,
							(doTiming
								ifTrue: [ ' - total time: ' , time printString , ' milliseconds. **' ]
							  	ifFalse: [ '**' ]) ]].
	^ result.
]

{ #category : 'logging to file' }
GbsCallTracing class >> startCallTracingToFile
[
	"Turn on call tracing to record the traces to a default file.
	 Answer the resulting logger."
	"GbsCallTracing startCallTracingToFile"

	^self startCallTracingToFileNamed: self defaultLogFileName
]

{ #category : 'logging to file' }
GbsCallTracing class >> traceFor: aBlock withTiming: doTiming
[
	"Enable GemBuilder & GCI tracing during the execution of aBlock (a zero-argument block).
	 Wrap the trace output with banner strings before and after.  Invocations of traceFor: can be nested;
	 the banners will keep track of the nesting and enabling of logging will be controlled properly.
	 If doTiming is true, the time to run the block is printed in the trace.
	 Answer the result of evaluating the block."

	^ self traceFor: aBlock withTiming: doTiming startMessage: nil endMessage: nil
]

{ #category : 'logging to file' }
GbsCallTracing class >> traceFor: aBlock
[
	"Enable GemBuilder & GCI tracing during the execution of aBlock (a zero-argument block).
	 See GbxStatManager class>>#traceFor:withTiming:startMessage:endMessage:."

	^ self traceFor: aBlock withTiming: false
]

{ #category : 'private' }
GbsCallTracing class >> privateStopCallTracing
[
	"Turns off call tracing, if presently on. Should only be sent under mutex protection."

	self isCallTracingActive ifFalse:[^self].
	Logger stopLogging.
	Logger := nil.
]

{ #category : 'private' }
GbsCallTracing class >> defaultLogFileName
[

	^'gbstrace-' , GbsStackDumper timestampForFilename , '.log'
]

{ #category : 'private' }
GbsCallTracing class >> logger
[
	"Currently only used by tests"

	^Logger
]

{ #category : 'logging' }
GbsCallTracing class >> logMessage: messageString
[

	Logger logMessage: messageString
]

{ #category : 'logging' }
GbsCallTracing class >> stopCallTracing
[
	"Turns off call tracing, if presently on.
	 Be sure to write out all trace data. It's important for memory tracing."
	"GbsCallTracing stopCallTracing"

	mutex critical: 
			[self
				writeToFile;
				privateStopCallTracing]
]

