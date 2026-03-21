Class {
	#name : 'NamedVariable',
	#superclass : 'Object',
	#instVars : [
		'object',
		'name',
		'index',
		'protected'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
NamedVariable >> of: anObject named: aString value: aValue cachedPrintString: aString index: anInteger
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> cachedPrintString: aString
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> delegate: anObject
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> index: anInteger
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> initialize
[
	protected := false
]

{ #category : 'accessing' }
NamedVariable >> name: aString
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> text
[
	"VisualWorks compatibility stub"
	^''
]

{ #category : 'accessing' }
NamedVariable >> value
[
	"VisualWorks compatibility stub"
	^nil
]

{ #category : 'accessing' }
NamedVariable >> value: anObject
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
NamedVariable >> beProtected
[
	protected := true
]

{ #category : 'accessing' }
NamedVariable >> object
[
	^object
]

{ #category : 'accessing' }
NamedVariable >> object: anObject
[
	object := anObject
]
