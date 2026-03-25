Class {
	#name : 'GbxLoggerTool',
	#superclass : 'Object',
	#instVars : [
		'logLevel',
		'isEnabled',
		'logCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxLoggerTool class >> new [
	^ super new
		initialize;
		yourself
]

{ #category : 'logging' }
GbxLoggerTool >> debug: aString [
	"Log a debug message"
	(self shouldLog: #debug) ifTrue: [
		self log: 'DEBUG: ', aString.
	].
]

{ #category : 'accessing' }
GbxLoggerTool >> disable [
	"Disable logging"
	isEnabled := false.
]

{ #category : 'accessing' }
GbxLoggerTool >> enable [
	"Enable logging"
	isEnabled := true.
]

{ #category : 'logging' }
GbxLoggerTool >> error: aString [
	"Log an error message"
	(self shouldLog: #error) ifTrue: [
		self logError: aString.
	].
]

{ #category : 'logging' }
GbxLoggerTool >> info: aString [
	"Log an info message"
	(self shouldLog: #info) ifTrue: [
		self logInfo: aString.
	].
]

{ #category : 'initialization' }
GbxLoggerTool >> initialize [
	super initialize.
	logLevel := #info.
	isEnabled := true.
	logCount := 0.
]

{ #category : 'accessing' }
GbxLoggerTool >> isEnabled [
	^ isEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
GbxLoggerTool >> isEnabled: aBoolean [
	isEnabled := aBoolean
]

{ #category : 'logging' }
GbxLoggerTool >> log: aString [
	"Log a message - subclass responsibility"
	self subclassResponsibility
]

{ #category : 'logging' }
GbxLoggerTool >> logCount [
	^ logCount ifNil: [ 0 ]
]

{ #category : 'logging' }
GbxLoggerTool >> logError: aString [
	"Log an error message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]

{ #category : 'logging' }
GbxLoggerTool >> logInfo: aString [
	"Log an info message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]

{ #category : 'accessing' }
GbxLoggerTool >> logLevel [
	^ logLevel
]

{ #category : 'accessing' }
GbxLoggerTool >> logLevel: aSymbol [
	"Set log level: #debug, #info, #warning, #error"
	logLevel := aSymbol.
]

{ #category : 'logging' }
GbxLoggerTool >> logWarning: aString [
	"Log a warning message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]

{ #category : 'logging' }
GbxLoggerTool >> shouldLog: levelSymbol [
	"Determine if a message at the given level should be logged"
	
	isEnabled ifFalse: [ ^ false ].
	
	^ self shouldLogLevel: levelSymbol beLoggedAt: logLevel.
]

{ #category : 'logging' }
GbxLoggerTool >> shouldLogLevel: msgLevel beLoggedAt: currentLevel [
	"Determine if msgLevel should be logged at currentLevel"
	| levels msgIndex currentIndex |
	
	levels := #( #debug #info #warning #error ).
	msgIndex := levels indexOf: msgLevel ifAbsent: [ 2 ].
	currentIndex := levels indexOf: currentLevel ifAbsent: [ 2 ].
	
	^ msgIndex >= currentIndex.
]

{ #category : 'logging' }
GbxLoggerTool >> warning: aString [
	"Log a warning message"
	(self shouldLog: #warning) ifTrue: [
		self logWarning: aString.
	].
]
