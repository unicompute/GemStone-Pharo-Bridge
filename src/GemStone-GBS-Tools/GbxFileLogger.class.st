Class {
	#name : 'GbxFileLogger',
	#superclass : 'GbxLogger',
	#instVars : [
		'filePath',
		'fileStream',
		'maxFileSize',
		'currentFileSize'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxFileLogger class >> on: aFilePath [
	^ self new
		filePath: aFilePath;
		yourself
]

{ #category : 'instance creation' }
GbxFileLogger class >> on: aFilePath maxFileSize: bytes [
	^ self new
		filePath: aFilePath;
		maxFileSize: bytes;
		yourself
]

{ #category : 'logging' }
GbxFileLogger >> close [
	"Close the log file"
	fileStream ifNotNil: [
		fileStream close.
		fileStream := nil.
	].
]

{ #category : 'accessing' }
GbxFileLogger >> currentFileSize [
	^ currentFileSize ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFileLogger >> filePath [
	^ filePath
]

{ #category : 'accessing' }
GbxFileLogger >> filePath: aString [
	filePath := aString.
	self openFile.
]

{ #category : 'accessing' }
GbxFileLogger >> fileStream [
	^ fileStream
]

{ #category : 'initialization' }
GbxFileLogger >> initialize [
	super initialize.
	maxFileSize := 10485760. "10 MB default"
]

{ #category : 'logging' }
GbxFileLogger >> log: aString [
	"Log a message to file"
	
	self ensureOpen.
	
	fileStream ifNotNil: [
		| timestamp message |
		timestamp := DateAndTime now asString.
		message := '[', timestamp, '] ', aString, String cr.
		
		fileStream nextPutAll: message.
		fileStream flush.
		
		currentFileSize := currentFileSize + message size.
		
		"Rotate if needed"
		currentFileSize > maxFileSize ifTrue: [
			self rotateFile.
		].
	].
]

{ #category : 'logging' }
GbxFileLogger >> logError: aString [
	"Log an error message"
	self log: 'ERROR: ', aString.
]

{ #category : 'logging' }
GbxFileLogger >> logInfo: aString [
	"Log an info message"
	self log: 'INFO: ', aString.
]

{ #category : 'logging' }
GbxFileLogger >> logWarning: aString [
	"Log a warning message"
	self log: 'WARNING: ', aString.
]

{ #category : 'accessing' }
GbxFileLogger >> maxFileSize [
	^ maxFileSize
]

{ #category : 'accessing' }
GbxFileLogger >> maxFileSize: anInteger [
	maxFileSize := anInteger
]

{ #category : 'file handling' }
GbxFileLogger >> openFile [
	"Open the log file for appending"
	
	self close.
	
	filePath ifNotNil: [
		| fileRef |
		fileRef := filePath asFileReference.
		fileRef ensureExists.
		fileStream := fileRef writeStream.
		fileStream setToEnd.
		currentFileSize := fileRef size.
	].
]

{ #category : 'file handling' }
GbxFileLogger >> ensureOpen [
	"Ensure the file is open"
	fileStream ifNil: [
		self openFile.
	].
]

{ #category : 'file handling' }
GbxFileLogger >> rotateFile [
	"Rotate the log file"
	| oldPath newPath |
	
	self close.
	
	oldPath := filePath asFileReference.
	newPath := (filePath, '.old') asFileReference.
	
	oldPath exists ifTrue: [
		newPath exists ifTrue: [
			newPath delete.
		].
		oldPath moveTo: newPath.
	].
	
	self openFile.
]
