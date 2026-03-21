Class {
	#name : 'SetInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'linearized',
		'driver',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
SetInspector >> initialize: anObject
[
	object := anObject
]

{ #category : 'accessing' }
SetInspector >> object
[
	^object
]

{ #category : 'accessing' }
SetInspector >> object: anObject
[
	object := anObject
]

{ #category : 'accessing' }
SetInspector >> refresh
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
SetInspector >> session
[
	^session ifNil: [ object ifNotNil: [ object session ] ]
]

{ #category : 'accessing' }
SetInspector >> session: anObject
[
	session := anObject
]
