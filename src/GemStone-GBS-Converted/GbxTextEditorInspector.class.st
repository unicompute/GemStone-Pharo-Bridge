Class {
	#name : 'GbxTextEditorInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'session',
		'textHolder',
		'container'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxTextEditorInspector class >> gbxIsGbsInspector [
	^ true
]

{ #category : 'accessing' }
GbxTextEditorInspector class >> tabLabel [
	^ 'GS Text'
]

{ #category : 'accessing' }
GbxTextEditorInspector >> documentHolder [
	^ textHolder
]

{ #category : 'initialization' }
GbxTextEditorInspector >> initialize: anObject [
	object := anObject.
	session := (anObject respondsTo: #session)
		ifTrue: [ anObject session ]
		ifFalse: [ nil ].
	textHolder := GbxValueHolder new.
	self refresh.
	^ self
]

{ #category : 'accessing' }
GbxTextEditorInspector >> object [
	^ object
]

{ #category : 'actions' }
GbxTextEditorInspector >> refresh [
	| text |
	text := (object respondsTo: #refreshText)
		ifTrue: [ object refreshText ]
		ifFalse: [
			(object respondsTo: #text)
				ifTrue: [ object text ]
				ifFalse: [ '' ] ].
	textHolder value: text asString
]

{ #category : 'actions' }
GbxTextEditorInspector >> textAccepted: aController [
	| newText |
	newText := (aController respondsTo: #text)
		ifTrue: [ aController text asString ]
		ifFalse: [ aController asString ].
	(object respondsTo: #replaceTextWith:)
		ifTrue: [ object replaceTextWith: newText ].
	(object respondsTo: #text:)
		ifTrue: [ object text: newText ].
	textHolder value: newText.
	^ true
]
