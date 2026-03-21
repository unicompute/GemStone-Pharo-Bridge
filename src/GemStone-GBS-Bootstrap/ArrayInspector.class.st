Class {
	#name : 'ArrayInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'undoHistory',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
ArrayInspector >> initialize: anObject
[
	object := anObject.
	undoHistory := OrderedCollection new
]

{ #category : 'accessing' }
ArrayInspector >> object
[
	^object
]

{ #category : 'accessing' }
ArrayInspector >> object: anObject
[
	object := anObject
]

{ #category : 'accessing' }
ArrayInspector >> refresh
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
ArrayInspector >> session
[
	^session ifNil: [ object ifNotNil: [ object session ] ]
]

{ #category : 'accessing' }
ArrayInspector >> session: anObject
[
	session := anObject
]
