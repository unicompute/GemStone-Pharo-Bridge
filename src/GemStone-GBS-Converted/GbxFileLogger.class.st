Class {
	#name : 'GbxFileLogger',
	#superclass : 'GbxLogger',
	#instVars : [
		'loggingEnabled'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxFileLogger class >> usingFileNamed: aString [
	^ self new
		initializeWithFileName: aString;
		yourself
]

{ #category : 'logging' }
GbxFileLogger >> contents [
	"Return the contents of the log file"
	| fileRef |
	fileRef := filename asFileReference.
	^ fileRef exists ifTrue: [ fileRef contents asString ] ifFalse: [ '' ]
]

{ #category : 'initialize-release' }
GbxFileLogger >> initializeWithFileName: aString [
	super initializeWithFileName: aString.
	loggingEnabled := false
]

{ #category : 'logging' }
GbxFileLogger >> logMessage: aMessage [
	"Log the message to the file"
	loggingEnabled ifTrue: [
		| fileRef stream |
		fileRef := filename asFileReference.
		stream := fileRef writeStream.
		stream setToEnd.
		stream nextPutAll: aMessage; cr.
		stream close.
	]
]

{ #category : 'changing state' }
GbxFileLogger >> startLogging [
	"Start logging to the file"
	loggingEnabled := true
]

{ #category : 'changing state' }
GbxFileLogger >> stopLogging [
	"Stop logging to the file"
	loggingEnabled := false
]

{ #category : 'logging' }
GbxFileLogger >> writeToFile [
	"Do nothing, as the log is already written to file"
]
