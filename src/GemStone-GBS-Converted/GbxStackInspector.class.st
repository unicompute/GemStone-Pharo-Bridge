Class {
	#name : 'GbxStackInspector',
	#superclass : 'GbxContextInspector',
	#instVars : [
		'selectedFieldName'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'private-menu messages' }
GbxStackInspector >> copyField [
	selectedFieldName ifNil: [ ^ false ].
	^ self copyFieldNamed: selectedFieldName
]

{ #category : 'field list' }
GbxStackInspector >> fieldList [
	self hasServerContextObject ifTrue: [ ^ self serverFieldList ].
	^ super fieldList
]

{ #category : 'field list' }
GbxStackInspector >> selectedFieldName [
	^ selectedFieldName
]

{ #category : 'field list' }
GbxStackInspector >> selectedFieldName: aString [
	selectedFieldName := aString
]

{ #category : 'field list' }
GbxStackInspector >> serverFieldList [
	| names |
	names := [ object argNames ] on: Error do: [ #() ].
	(self properties at: #tempNames put: names).
	^ names
]

{ #category : 'text' }
GbxStackInspector >> stackStringAt: index [
	| names name value |
	self hasServerContextObject ifFalse: [ ^ '' ].
	names := self serverFieldList.
	(index isInteger and: [ index > 0 and: [ index <= names size ] ]) ifFalse: [ ^ '' ].
	name := names at: index.
	value := self fieldValueAtName: name.
	^ name asString , ':', (value ifNil: [ 'nil' ] ifNotNil: [ value asString ])
]
