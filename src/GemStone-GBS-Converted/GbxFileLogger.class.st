Class {
	#name : 'GbxFileLogger',
	#superclass : 'GbxLogger',
	#instVars : [
		'loggingEnabled'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'changing state' }
GbxFileLogger >> startLogging
[
	"Should not be sent by any other than GbsCallTracing>>startCallTracingToFileNamed:.
	If trace file is set to null when already null, tracing goes to stdout, which we don't want."
	
	GBSM serverInterface enableTracingToFileNamed: filename.
	loggingEnabled := true
]

{ #category : 'changing state' }
GbxFileLogger >> stopLogging
[
	"Should not be sent by any other than GbsCallTracing>>privateStopCallTracing.
	If trace file is set to null when already null, tracing goes to stdout, which we don't want."
	
	loggingEnabled ifFalse: [^self].
	loggingEnabled := false.
	GBSM serverInterface disableTracingToFile.
]

{ #category : 'logging' }
GbxFileLogger >> writeToFile
[
	"Do nothing, as the call tracing log is already written to file by the GCI library."
]

{ #category : 'logging' }
GbxFileLogger >> logMessage: aMessage
[

	"Log the message to the gci trace file"
	loggingEnabled 
		ifTrue: [GBSM serverInterface printOnTraceFile: aMessage]
]

{ #category : 'initialize-release' }
GbxFileLogger >> initializeWithFileName: aString
[

	super initializeWithFileName: aString.
	loggingEnabled := false
]

