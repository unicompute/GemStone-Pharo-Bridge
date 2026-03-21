Class {
	#name : 'DictionaryInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'driver',
		'linearizedParts',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
DictionaryInspector >> initialize: anObject
[
	object := anObject
]

{ #category : 'accessing' }
DictionaryInspector >> object
[
	^object
]

{ #category : 'accessing' }
DictionaryInspector >> object: anObject
[
	object := anObject
]

{ #category : 'accessing' }
DictionaryInspector >> refresh
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
DictionaryInspector >> session
[
	^session ifNil: [ object ifNotNil: [ object session ] ]
]

{ #category : 'accessing' }
DictionaryInspector >> session: anObject
[
	session := anObject
]
