Class {
	#name : 'CompletionDriver',
	#superclass : 'Object',
	#instVars : [
		'widget',
		'choicesHolder',
		'caseInsensitive',
		'auto'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'initialization' }
CompletionDriver >> initialize
[
	super initialize.
	caseInsensitive := false.
	auto := true
]

{ #category : 'accessing' }
CompletionDriver >> beCaseInsensitive
[
	caseInsensitive := true.
	^ self
]

{ #category : 'accessing' }
CompletionDriver >> beNotAuto
[
	auto := false.
	^ self
]

{ #category : 'accessing' }
CompletionDriver >> choices
[
	^ choicesHolder
		ifNil: [ #() ]
		ifNotNil: [ choicesHolder value ]
]

{ #category : 'accessing' }
CompletionDriver >> choicesHolder: aBlock
[
	choicesHolder := aBlock.
	^ self
]

{ #category : 'accessing' }
CompletionDriver >> isAuto
[
	^ auto
]

{ #category : 'accessing' }
CompletionDriver >> isCaseInsensitive
[
	^ caseInsensitive
]

{ #category : 'accessing' }
CompletionDriver >> widget
[
	^ widget
]

{ #category : 'accessing' }
CompletionDriver >> widget: anObject
[
	widget := anObject.
	^ self
]
