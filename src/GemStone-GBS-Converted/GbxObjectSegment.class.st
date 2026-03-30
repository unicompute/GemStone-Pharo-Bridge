Class {
	#name : 'GbxObjectSegment',
	#superclass : 'Object',
	#instVars : [
		'firstIndex',
		'firstPart',
		'lastIndex',
		'lastPart',
		'isUncached'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxObjectSegment >> < aSegment [
	^ self firstIndex < aSegment firstIndex
]

{ #category : 'state' }
GbxObjectSegment >> cached [
	isUncached := false
]

{ #category : 'accessing' }
GbxObjectSegment >> firstIndex [
	^ firstIndex
]

{ #category : 'accessing' }
GbxObjectSegment >> firstPart [
	^ firstPart
]

{ #category : 'accessing' }
GbxObjectSegment >> firstPart: anObject [
	firstPart := anObject
]

{ #category : 'initialization' }
GbxObjectSegment >> from: startIndex part: startPart to: endIndex part: endPart [
	firstIndex := startIndex.
	firstPart := startPart.
	lastIndex := endIndex.
	lastPart := endPart
]

{ #category : 'testing' }
GbxObjectSegment >> isUncached [
	^ isUncached ifNil: [ false ]
]

{ #category : 'testing' }
GbxObjectSegment >> isUncached: aBoolean [
	isUncached := aBoolean
]

{ #category : 'accessing' }
GbxObjectSegment >> lastIndex [
	^ lastIndex
]

{ #category : 'accessing' }
GbxObjectSegment >> lastPart [
	^ lastPart
]

{ #category : 'accessing' }
GbxObjectSegment >> lastPart: anObject [
	lastPart := anObject
]
