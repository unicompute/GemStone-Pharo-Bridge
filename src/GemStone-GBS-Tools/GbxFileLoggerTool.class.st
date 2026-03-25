Class {
	#name : 'GbxFileLoggerTool',
	#superclass : 'GbxLoggerTool',
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
GbxFileLoggerTool class >> on: aFilePath [
	^ self new
		filePath: aFilePath;
		yourself
]

{ #category : 'instance creation' }
GbxFileLoggerTool class >> on: aFilePath maxFileSize: bytes [
	^ self new
		filePath: aFilePath;
		maxFileSize: bytes;
		yourself
]

{ #category : 'logging' }
GbxFileLoggerTool >> close [
	"Close the log file"
	fileStream ifNotNil: [
		fileStream close.
		fileStream := nil.
	].
]

{ #category : 'accessing' }
GbxFileLoggerTool >> currentFileSize [
	^ currentFileSize ifNil: [ 0 ]
]

{ #category : 'file handling' }
GbxFileLoggerTool >> ensureOpen [
	"Ensure the file is open"
	fileStream ifNil: [
		self openFile.
	].
]

{ #category : 'accessing' }
GbxFileLoggerTool >> filePath [
	^ filePath
]

{ #category : 'accessing' }
GbxFileLoggerTool >> filePath: aString [
	filePath := aString.
	self openFile.
]

{ #category : 'accessing' }
GbxFileLoggerTool >> fileStream [
	^ fileStream
]

{ #category : 'initialization' }
GbxFileLoggerTool >> initialize [
	super initialize.
	maxFileSize := 10485760. "10 MB default"
]

{ #category : 'logging' }
GbxFileLoggerTool >> log: aString [
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
GbxFileLoggerTool >> logError: aString [
	"Log an error message"
	self log: 'ERROR: ', aString.
]

{ #category : 'logging' }
GbxFileLoggerTool >> logInfo: aString [
	"Log an info message"
	self log: 'INFO: ', aString.
]

{ #category : 'logging' }
GbxFileLoggerTool >> logWarning: aString [
	"Log a warning message"
	self log: 'WARNING: ', aString.
]

{ #category : 'accessing' }
GbxFileLoggerTool >> maxFileSize [
	^ maxFileSize
]

{ #category : 'accessing' }
GbxFileLoggerTool >> maxFileSize: anInteger [
	maxFileSize := anInteger
]

{ #category : 'file handling' }
GbxFileLoggerTool >> openFile [
	"Open the log file for appending"
	
	self close.
	
	filePath ifNotNil: [
		| ref |
		ref := filePath asFileReference.
		fileStream := ref exists
			ifTrue: [ ref readWriteStream ]
			ifFalse: [ ref writeStream ].
		fileStream setToEnd.
		currentFileSize := fileStream position.
	].
]

{ #category : 'file handling' }
GbxFileLoggerTool >> rotateFile [
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
