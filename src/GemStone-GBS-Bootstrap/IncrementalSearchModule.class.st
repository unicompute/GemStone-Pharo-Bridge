Class {
	#name : 'IncrementalSearchModule',
	#superclass : 'Object',
	#instVars : [
		'entryModule',
		'searchDriver',
		'searchBlock',
		'guessDriver',
		'session',
		'firstLabel',
		'secondLabel',
		'objectToStringBlock',
		'displayStringSelector',
		'iconSelector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
IncrementalSearchModule >> forGemStoneClassSelection: anObject browser: aBrowser
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
IncrementalSearchModule >> session
[
	^session
]

{ #category : 'accessing' }
IncrementalSearchModule >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
IncrementalSearchModule >> setupDrivers
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
IncrementalSearchModule >> acceptSearchResults: anObject
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
IncrementalSearchModule >> currentStrings
[
	^#()
]

{ #category : 'accessing' }
IncrementalSearchModule >> displayStringSelector: aSymbol
[
	displayStringSelector := aSymbol.
	^self
]

{ #category : 'accessing' }
IncrementalSearchModule >> firstLabel: aString
[
	firstLabel := aString.
	^self
]

{ #category : 'accessing' }
IncrementalSearchModule >> iconSelector: aSymbol
[
	iconSelector := aSymbol.
	^self
]

{ #category : 'accessing' }
IncrementalSearchModule >> objectToStringBlock: aBlock
[
	objectToStringBlock := aBlock.
	^self
]

{ #category : 'accessing' }
IncrementalSearchModule >> searchBlock: aBlock
[
	searchBlock := aBlock.
	^self
]

{ #category : 'accessing' }
IncrementalSearchModule >> secondLabel: aString
[
	secondLabel := aString.
	^self
]
