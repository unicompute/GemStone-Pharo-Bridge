Class {
	#name : #'GbxMemoryLogger',
	#superclass : #'GbxLogger',
	#instVars : [ #'buffer' #'position' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'changing state' }
GbxMemoryLogger >> stopLogging
	"We have no special work to do to stop logging."

{ #category : #'logging' }
GbxMemoryLogger >> writeOn: aStream

	| oldestStartPosition |
	oldestStartPosition := ((buffer at: position) asInteger == 0
				and: [(buffer at: buffer size) asInteger == 0])
					ifTrue: [buffer size + 1]
					ifFalse: [position].	"Ignore this part of the buffer if we haven't even filled it up once yet"
	aStream
		nextPutAll: (buffer copyFrom: oldestStartPosition to: buffer size);
		nextPutAll: (buffer copyFrom: 1 to: position - 1)

{ #category : #'logging' }
GbxMemoryLogger >> logMessage: aMessage

	"Log the message to the memory-based stream"

	self
		nextPutAll: aMessage;
		nextPutAll: self class newline

{ #category : #'logging' }
GbxMemoryLogger >> nextPutAll: aMessage

	"Log the message to the memory-based stream"

	| trimmedMsg maxIndex wrapIndex |

	"If a single message is larger than the buffer, discard the beginning"
	trimmedMsg := aMessage.
	(aMessage size > buffer size) ifTrue: [
		trimmedMsg := aMessage copyFrom: aMessage size - buffer size + 1 to: aMessage size.
	].

	maxIndex := position + trimmedMsg size - 1.
	wrapIndex := nil.
	(maxIndex > buffer size) ifTrue: [
		"The end of the message will wrap back to the beginning of the buffer"
		wrapIndex := maxIndex - buffer size.
		maxIndex := buffer size.
	].

	buffer replaceFrom: position to: maxIndex with: trimmedMsg startingAt: 1.
	wrapIndex isNil ifFalse: [
		buffer replaceFrom: 1 to: wrapIndex with: trimmedMsg startingAt: maxIndex - position + 2.
	].
	position := position + trimmedMsg size.
	position > buffer size ifTrue: [ position := position - buffer size ]

{ #category : #'logging' }
GbxMemoryLogger >> writeToFile
	"Dump the contents of the buffer to file.  Return the name of the file (a GbxFilename)"

	| aStream fileName |
	fileName := GbxFilename named: filename.
	aStream := fileName writeStream.
	self writeOn: aStream.
	aStream close.
	^fileName

{ #category : #'logging' }
GbxMemoryLogger >> contents
	"Answer the contents of this buffer."

	| aStream |
	aStream := String new writeStream.
	self writeOn: aStream.
	^aStream contents

{ #category : #'initialize-release' }
GbxMemoryLogger >> initializeWithBufferSized: aNumber andFileName: aString

	self initializeWithFileName: aString.
	self initializeBufferOfSize: aNumber

{ #category : #'initialize-release' }
GbxMemoryLogger >> initializeBufferOfSize: anInteger

	buffer := String new: anInteger.
	position := 1

{ #category : #'initialize-release' }
GbxMemoryLogger >> initializeWithBufferOfMegabytes: aNumber andFileName: aString

	self initializeWithBufferSized: (aNumber * self bytesPerMegabyte) ceiling
		andFileName: aString

{ #category : #'initialize-release' }
GbxMemoryLogger >> bytesPerMegabyte

	^1048576

{ #category : #'initialization' }
GbxMemoryLogger class >> initialize

	Newline := String with: Character lf

{ #category : #'instance creation' }
GbxMemoryLogger class >> usingBufferOfMegabytes: aNumber andFileNamed: aString

	^(self new)
		initializeWithBufferOfMegabytes: aNumber andFileName: aString;
		yourself

{ #category : #'instance creation' }
GbxMemoryLogger class >> usingFileNamed: aString

	^self usingBufferOfMegabytes: self defaultBufferSizeInMegabytes
		andFileNamed: aString

{ #category : #'constants' }
GbxMemoryLogger class >> defaultBufferSizeInMegabytes

	^1

{ #category : #'constants' }
GbxMemoryLogger class >> newline

	Newline isNil ifTrue: [ self initialize ].
	^Newline

