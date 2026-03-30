Class {
	#name : 'GbxProxyReceiverInspector',
	#superclass : 'GbxReceiverInspector',
	#instVars : [
		'field',
		'originalProxy',
		'objectIsRemote'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxProxyReceiverInspector >> basicPrintStringFor: anObject [
	^ anObject printString
]

{ #category : 'printing' }
GbxProxyReceiverInspector >> delegateFieldName [
	^ '.delegate'
]

{ #category : 'accessing' }
GbxProxyReceiverInspector >> fieldValue [
	field = self selfFieldName ifTrue: [ ^ originalProxy ].
	field = self serverFieldName ifTrue: [ ^ object ].
	field = self delegateFieldName ifTrue: [ ^ object ].
	^ nil
]

{ #category : 'field list' }
GbxProxyReceiverInspector >> fieldValueAtName: aName [
	field := aName.
	^ self fieldValue
]

{ #category : 'printing' }
GbxProxyReceiverInspector >> gbxBasicTextOn: aStream [
	| value |
	value := self fieldValue.
	value ifNil: [ ^ '' ].
	(value respondsTo: #gbxDebugPrintOn:)
		ifTrue: [ value gbxDebugPrintOn: aStream ]
		ifFalse: [ value printOn: aStream ].
	^ aStream contents
]

{ #category : 'field list' }
GbxProxyReceiverInspector >> gbxFieldList [
	^ {
		self selfFieldName.
		self delegateFieldName.
		self serverFieldName
	}
]

{ #category : 'accessing' }
GbxProxyReceiverInspector >> gbxContextObject [
	^ object
]

{ #category : 'field list' }
GbxProxyReceiverInspector >> fieldList [
	^ self gbxFieldList
]

{ #category : 'accessing' }
GbxProxyReceiverInspector >> objectIsRemote: aBoolean [
	objectIsRemote := aBoolean
]

{ #category : 'accessing' }
GbxProxyReceiverInspector >> originalProxy: anObject [
	originalProxy := anObject
]

{ #category : 'printing' }
GbxProxyReceiverInspector >> selfFieldName [
	^ 'self'
]

{ #category : 'printing' }
GbxProxyReceiverInspector >> serverFieldName [
	^ '.server'
]
