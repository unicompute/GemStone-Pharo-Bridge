Class {
	#name : 'GbxObjectSegment',
	#superclass : 'ObjectSegment',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxObjectSegment >> isUncached
[
	^isUncached
]

{ #category : 'accessing' }
GbxObjectSegment >> isUncached: anObject
[
	isUncached := anObject
]

{ #category : 'accessing' }
GbxObjectSegment >> cached
[
	isUncached := false
]

{ #category : 'accessing' }
GbxObjectSegment >> firstPart: anObject
[
	firstPart := anObject
]

{ #category : 'accessing' }
GbxObjectSegment >> lastPart: anObject
[
	lastPart := anObject
]
