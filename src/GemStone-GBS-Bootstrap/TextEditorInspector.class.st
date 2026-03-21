Class {
	#name : 'TextEditorInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'textHolder',
		'container',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'testing' }
TextEditorInspector >> gbxIsGbsInspector
[
	"VisualWorks compatibility stub"
	^true
]

{ #category : 'accessing' }
TextEditorInspector >> tabLabel
[
	"VisualWorks compatibility stub"
	^'Text Editor'
]

{ #category : 'accessing' }
TextEditorInspector >> documentHolder
[
	^textHolder
]

{ #category : 'accessing' }
TextEditorInspector >> initialize: anObject
[
	object := anObject
]

{ #category : 'accessing' }
TextEditorInspector >> refresh
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
TextEditorInspector >> textAccepted: aString
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
TextEditorInspector >> object
[
	^object
]

{ #category : 'accessing' }
TextEditorInspector >> object: anObject
[
	object := anObject
]

{ #category : 'accessing' }
TextEditorInspector >> session
[
	^session ifNil: [ object ifNotNil: [ object session ] ]
]

{ #category : 'accessing' }
TextEditorInspector >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
TextEditorInspector >> textHolder
[
	^textHolder
]

{ #category : 'accessing' }
TextEditorInspector >> textHolder: anObject
[
	textHolder := anObject
]
