Class {
	#name : 'ObjectSegment',
	#superclass : 'Object',
	#instVars : [
		'firstIndex',
		'lastIndex',
		'firstPart',
		'lastPart',
		'isUncached'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
ObjectSegment >> cached
[
	isUncached := false
]

{ #category : 'accessing' }
ObjectSegment >> firstIndex
[
	^firstIndex
]

{ #category : 'accessing' }
ObjectSegment >> firstPart: anObject
[
	firstPart := anObject
]

{ #category : 'accessing' }
ObjectSegment >> from: start part: startPart to: stop part: stopPart
[
	firstIndex := start.
	lastIndex := stop.
	firstPart := startPart.
	lastPart := stopPart.
	^self
]

{ #category : 'testing' }
ObjectSegment >> isUncached
[
	^isUncached
]

{ #category : 'testing' }
ObjectSegment >> isUncached: aBoolean
[
	isUncached := aBoolean
]

{ #category : 'accessing' }
ObjectSegment >> lastIndex
[
	^lastIndex
]

{ #category : 'accessing' }
ObjectSegment >> lastPart: anObject
[
	lastPart := anObject
]
