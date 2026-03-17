Class {
	#name : #'GbxOverrideEditInsert',
	#superclass : #'GbxOverrideEdit',
	#instVars : [ #'string' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'storing' }
GbxOverrideEditInsert >> string: anObject

	string := anObject

{ #category : #'storing' }
GbxOverrideEditInsert >> string

	^string

{ #category : #'comparing' }
GbxOverrideEditInsert >> = anotherObject

	^self class = anotherObject class
		and: [self string = anotherObject string]

{ #category : #'accessing' }
GbxOverrideEditInsert >> count

	^self string size

{ #category : #'applying' }
GbxOverrideEditInsert >> applyFrom: inputStream to: outputStream

	outputStream nextPutAll: string

{ #category : #'initialize-release' }
GbxOverrideEditInsert >> initializeFromSubSequence: aSubSequence
	"Subsequence of TextFragments (which are Subsequences themselves)"

	| ss offset length lastFragment |
	ss := aSubSequence.
	offset := ss first offset.
	lastFragment := ss last.
	length := lastFragment  offset + lastFragment  length - offset.
	
	"Copy from the underlying source string."
	string := lastFragment sequence copyFrom: offset + 1 to: offset + length

{ #category : #'printing' }
GbxOverrideEditInsert >> storeOn: aStream

	aStream
		nextPutAll: self class fullName;
		nextPutAll: ' string: '.
	string storeOn: aStream

{ #category : #'instance creation' }
GbxOverrideEditInsert class >> string: aString

	^(self new)
		string: aString;
		yourself

