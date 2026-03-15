Class {
	#name : 'GbxLogger',
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
GbxLogger class >> new [
	^ super new
		initialize;
		yourself
]

{ #category : 'logging' }
GbxLogger >> debug: aString [
	"Log a debug message"
	(self shouldLog: #debug) ifTrue: [
		self log: 'DEBUG: ', aString.
	].
]

{ #category : 'accessing' }
GbxLogger >> disable [
	"Disable logging"
	isEnabled := false.
]

{ #category : 'accessing' }
GbxLogger >> enable [
	"Enable logging"
	isEnabled := true.
]

{ #category : 'logging' }
GbxLogger >> error: aString [
	"Log an error message"
	(self shouldLog: #error) ifTrue: [
		self logError: aString.
	].
]

{ #category : 'accessing' }
GbxLogger >> isEnabled [
	^ isEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
GbxLogger >> isEnabled: aBoolean [
	isEnabled := aBoolean
]

{ #category : 'initialization' }
GbxLogger >> initialize [
	super initialize.
	logLevel := #info.
	isEnabled := true.
	logCount := 0.
]

{ #category : 'logging' }
GbxLogger >> info: aString [
	"Log an info message"
	(self shouldLog: #info) ifTrue: [
		self logInfo: aString.
	].
]

{ #category : 'logging' }
GbxLogger >> log: aString [
	"Log a message - subclass responsibility"
	self subclassResponsibility
]

{ #category : 'logging' }
GbxLogger >> logCount [
	^ logCount ifNil: [ 0 ]
]

{ #category : 'logging' }
GbxLogger >> logError: aString [
	"Log an error message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]

{ #category : 'logging' }
GbxLogger >> logInfo: aString [
	"Log an info message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]

{ #category : 'accessing' }
GbxLogger >> logLevel [
	^ logLevel
]

{ #category : 'accessing' }
GbxLogger >> logLevel: aSymbol [
	"Set log level: #debug, #info, #warning, #error"
	logLevel := aSymbol.
]

{ #category : 'logging' }
GbxLogger >> shouldLog: levelSymbol [
	"Determine if a message at the given level should be logged"
	
	isEnabled ifFalse: [ ^ false ].
	
	^ self shouldLogLevel: levelSymbol beLoggedAt: logLevel.
]

{ #category : 'logging' }
GbxLogger >> shouldLogLevel: msgLevel beLoggedAt: currentLevel [
	"Determine if msgLevel should be logged at currentLevel"
	| levels msgIndex currentIndex |
	
	levels := #( #debug #info #warning #error ).
	msgIndex := levels indexOf: msgLevel ifAbsent: [ 2 ].
	currentIndex := levels indexOf: currentLevel ifAbsent: [ 2 ].
	
	^ msgIndex >= currentIndex.
]

{ #category : 'logging' }
GbxLogger >> warning: aString [
	"Log a warning message"
	(self shouldLog: #warning) ifTrue: [
		self logWarning: aString.
	].
]

{ #category : 'logging' }
GbxLogger >> logWarning: aString [
	"Log a warning message - subclass responsibility"
	self log: aString.
	logCount := logCount + 1.
]
