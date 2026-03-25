Class {
	#name : 'GbsCallTracing',
	#superclass : 'Object',
	#classInstVars : [
		'mutex',
		'Logger'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsCallTracing class >> isCallTracingActive [
	^ Logger isNotNil
]

{ #category : 'accessing' }
GbsCallTracing class >> logger [
	^ Logger
]

{ #category : 'logging to file' }
GbsCallTracing class >> startCallTracingToFileNamed: filename [
	"Turn on call tracing to record the traces to the specified file.
	 Answer the resulting logger."
	Logger := GbxFileLogger usingFileNamed: filename.
	Logger startLogging.
	^ Logger
]

{ #category : 'logging' }
GbsCallTracing class >> logMessage: aString [
	"Log a message to the current logger"
	Logger ifNotNil: [ Logger logMessage: aString ]
]

{ #category : 'logging' }
GbsCallTracing class >> stopCallTracing [
	"Turns off call tracing, if presently on"
	self isCallTracingActive ifTrue: [
		Logger ifNotNil: [
			Logger stopLogging.
			Logger := nil
		]
	]
]

{ #category : 'logging to file' }
GbsCallTracing class >> writeToFile [
	"Write the current log to file"
	Logger ifNotNil: [ Logger writeToFile ]
]
