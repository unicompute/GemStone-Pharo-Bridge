Class {
	#name : 'GbxOverrideEditWithCount',
	#superclass : 'GbxOverrideEdit',
	#instVars : [
		'count'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxOverrideEditWithCount >> = anotherObject

	^self class = anotherObject class
		and: [self count = anotherObject count]

{ #category : 'accessing' }
GbxOverrideEditWithCount >> count

	^count

{ #category : 'accessing' }
GbxOverrideEditWithCount >> count: anObject

	count := anObject

{ #category : 'storing' }
GbxOverrideEditWithCount >> storeOn: aStream

	aStream
		nextPutAll: self class fullName;
		nextPutAll: ' count: '.
	count storeOn: aStream

{ #category : 'initialize-release' }
GbxOverrideEditWithCount >> initializeFromSubSequence: aSubSequence
	"Subsequence of TextFragments (which are Subsequences themselves)"

	| ss offset length lastFragment |
	ss := aSubSequence.
	offset := ss first offset.
	lastFragment := ss last.
	length := lastFragment  offset + lastFragment  length - offset.

	count := length

{ #category : 'instance creation' }
GbxOverrideEditWithCount class >> count: anInteger

	^(self new)
		count: anInteger;
		yourself

