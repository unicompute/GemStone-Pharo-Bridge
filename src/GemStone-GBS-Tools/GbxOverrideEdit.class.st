Class {
	#name : 'GbxOverrideEdit',
	#superclass : 'GbxOverride',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'comparing' }
GbxOverrideEdit >> hash
[
	"Override edits do not make sense in a hashed collection; punt to the default implementation."

	^super hash
]

{ #category : 'comparing' }
GbxOverrideEdit >> = anotherObject
[

	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxOverrideEdit >> count
[
	"Answer the size of the edit"
	
	^self subclassResponsibility
]

{ #category : 'initialize-release' }
GbxOverrideEdit >> initializeFromSubSequence: aSubSequence
[
	self subclassResponsibility
]

{ #category : 'initialize-release' }
GbxOverrideEdit >> initializeFromSubSequence: aSubSequence forParent: aMethodVersionOverride
[
	parent := aMethodVersionOverride.
	self initializeFromSubSequence: aSubSequence
]

{ #category : 'printing' }
GbxOverrideEdit >> printOn: aStream
[
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: self count;
		nextPutAll: ')'
]

{ #category : 'applying' }
GbxOverrideEdit >> applyFrom: inputStream to: outputStream
[
	self subclassResponsibility
]

{ #category : 'private' }
GbxOverrideEdit class >> classForSubSequence: aSubSequence
[
	aSubSequence isMatch ifTrue: [^GbxOverrideEditCopy].
	aSubSequence isInsert ifTrue: [^GbxOverrideEditInsert].
	aSubSequence isDelete ifTrue: [^GbxOverrideEditDelete].
	self error: 'Unknown subSequence type'
]

{ #category : 'instance creation' }
GbxOverrideEdit class >> fromSubSequence: aSubSequence forParent: aMethodVersionOverride
[
	^((self classForSubSequence: aSubSequence) new)
		initializeFromSubSequence: aSubSequence forParent: aMethodVersionOverride;
		yourself
]

