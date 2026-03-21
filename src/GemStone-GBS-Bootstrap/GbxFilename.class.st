Class {
	#name : 'GbxFilename',
	#superclass : 'Object',
	#instVars : [
		'reference',
		'encoding'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'defaults' }
GbxFilename class >> concreteClass
[
	^ self
]

{ #category : 'defaults' }
GbxFilename class >> currentDirectory
[
	^ self fromReference: FileSystem workingDirectory encoding: nil
]

{ #category : 'defaults' }
GbxFilename class >> defaultClass
[
	^ self concreteClass
]

{ #category : 'instance creation' }
GbxFilename class >> fromReference: aReference encoding: anEncoding
[
	^ self basicNew
		reference: aReference;
		encoding: anEncoding;
		yourself
]

{ #category : 'instance creation' }
GbxFilename class >> named: aPathLike
[
	aPathLike isNil ifTrue: [ ^ self currentDirectory ].
	aPathLike class == self ifTrue: [ ^ aPathLike ].
	^ self
		fromReference: aPathLike asFileReference
		encoding: nil
]

{ #category : 'defaults' }
GbxFilename class >> suggest: aString
[
	| candidate extension lastDot lastSlash stem index |
	candidate := aString asString.
	(self named: candidate) exists ifFalse: [ ^ candidate ].
	lastDot := candidate lastIndexOf: $. ifAbsent: [ 0 ].
	lastSlash := (candidate lastIndexOf: $/ ifAbsent: [ 0 ])
		max: (candidate lastIndexOf: $\ ifAbsent: [ 0 ]).
	(lastDot > lastSlash)
		ifTrue: [
			stem := candidate copyFrom: 1 to: lastDot - 1.
			extension := candidate copyFrom: lastDot to: candidate size ]
		ifFalse: [
			stem := candidate.
			extension := '' ].
	index := 1.
	[
		candidate := stem , '-' , index asString , extension.
		(self named: candidate) exists
	] whileTrue: [ index := index + 1 ].
	^ candidate
]

{ #category : 'converting' }
GbxFilename >> asFileReference
[
	^ reference
]

{ #category : 'converting' }
GbxFilename >> asString
[
	^ reference fullName
]

{ #category : 'accessing' }
GbxFilename >> encoding
[
	^ encoding
]

{ #category : 'accessing' }
GbxFilename >> encoding: aSymbol
[
	encoding := aSymbol.
	^ self
]

{ #category : 'testing' }
GbxFilename >> exists
[
	^ [ reference exists ] on: Error do: [ false ]
]

{ #category : 'accessing' }
GbxFilename >> fullName
[
	^ reference fullName
]

{ #category : 'printing' }
GbxFilename >> printOn: aStream
[
	aStream nextPutAll: self asString
]

{ #category : 'accessing' }
GbxFilename >> readStream
[
	^ reference readStream
]

{ #category : 'private' }
GbxFilename >> reference: anObject
[
	reference := anObject asFileReference.
	^ self
]

{ #category : 'accessing' }
GbxFilename >> withEncoding: aSymbol
[
	^ self class
		fromReference: reference
		encoding: aSymbol
]

{ #category : 'accessing' }
GbxFilename >> writeStream
[
	encoding = #binary ifTrue: [
		^ [ reference binaryWriteStream ]
			on: Error
			do: [ reference writeStream ] ].
	^ reference writeStream
]
