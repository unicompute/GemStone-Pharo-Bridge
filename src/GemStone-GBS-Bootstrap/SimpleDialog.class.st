Class {
	#name : 'SimpleDialog',
	#superclass : 'Object',
	#instVars : [
		'postOpenBlock'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'private' }
SimpleDialog >> canHandleLegacyAddClassDialog: anObject
[
	^ #(newClassName superClassName newInstVars newClassVars modifiable)
		allSatisfy: [ :selector | anObject respondsTo: selector ]
]

{ #category : 'private' }
SimpleDialog >> openLegacyAddClassDialogFor: aModel
[
	| className superclassName instanceVariables classVariables modifiableHolder |
	className := GbxDialog
		request: 'New Class:'
		initialAnswer: (self stringValueForHolder: aModel newClassName).
	className ifNil: [ ^ false ].
	superclassName := GbxDialog
		request: 'Superclass:'
		initialAnswer: (self stringValueForHolder: aModel superClassName).
	superclassName ifNil: [ ^ false ].
	instanceVariables := GbxDialog
		request: 'Instance Variables:'
		initialAnswer: (self stringValueForHolder: aModel newInstVars).
	instanceVariables ifNil: [ ^ false ].
	classVariables := GbxDialog
		request: 'Class Variables:'
		initialAnswer: (self stringValueForHolder: aModel newClassVars).
	classVariables ifNil: [ ^ false ].
	self
		storeString: className inHolder: aModel newClassName;
		storeString: superclassName inHolder: aModel superClassName;
		storeString: instanceVariables inHolder: aModel newInstVars;
		storeString: classVariables inHolder: aModel newClassVars.
	modifiableHolder := aModel modifiable.
	(modifiableHolder respondsTo: #value:)
		ifTrue: [ modifiableHolder value: (GbxDialog confirm: 'Create class as modifiable?') ].
	^ true
]

{ #category : 'opening' }
SimpleDialog >> openFor: anObject interface: aSelector
[
	(self canHandleLegacyAddClassDialog: anObject)
		ifTrue: [ ^ self openLegacyAddClassDialogFor: anObject ].
	^ false
]

{ #category : 'accessing' }
SimpleDialog >> postOpenBlock: aBlock
[
	postOpenBlock := aBlock.
	^ self
]

{ #category : 'private' }
SimpleDialog >> storeString: aString inHolder: aHolder
[
	(aHolder respondsTo: #value:)
		ifTrue: [ aHolder value: aString asText ].
	^ aString
]

{ #category : 'private' }
SimpleDialog >> stringValueForHolder: aHolder
[
	| value |
	value := (aHolder respondsTo: #value)
		ifTrue: [ aHolder value ]
		ifFalse: [ aHolder ].
	^ value
		ifNil: [ '' ]
		ifNotNil: [ value asString ]
]
