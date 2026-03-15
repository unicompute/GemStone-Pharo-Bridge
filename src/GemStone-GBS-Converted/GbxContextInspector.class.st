Class {
	#name : 'GbxContextInspector',
	#superclass : 'Object',
	#instVars : [
		'service',
		'object',
		'properties',
		'contextOop',
		'activation'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxContextInspector class >> openOn: anObject service: aService [
	| inspector |
	inspector := self new.
	inspector
		object: anObject;
		service: aService.
	inspector inspect.
	^ inspector
]

{ #category : 'accessing' }
GbxContextInspector >> object [
	^ object
]

{ #category : 'accessing' }
GbxContextInspector >> object: anObject [
	object := anObject
]

{ #category : 'accessing' }
GbxContextInspector >> properties [
	properties ifNil: [ properties := Dictionary new ].
	^ properties
]

{ #category : 'accessing' }
GbxContextInspector >> service [
	^ service
]

{ #category : 'accessing' }
GbxContextInspector >> service: anObject [
	service := anObject
]

{ #category : 'accessing' }
GbxContextInspector >> gbxDoItAgent [
	"VW parity: execute in the debugger service when available."
	^ service
]

{ #category : 'testing' }
GbxContextInspector >> hasServerContextObject [
	^ (object respondsTo: #gbxIsServerContext)
		and: [ object gbxIsServerContext = true ]
]

{ #category : 'doIt/accept' }
GbxContextInspector >> evaluateText: aText from: aController ifFail: failBlock [
	"VW parity hook: server contexts evaluate remotely in selected frame."
	self hasServerContextObject ifFalse: [ ^ failBlock value ].
	^ self gbxServerEvaluateText: aText from: aController ifFail: failBlock
]

{ #category : 'doIt/accept' }
GbxContextInspector >> gbxServerEvaluateText: aString from: aController ifFail: failBlock [
	| text raw session contextOop |
	text := aString ifNil: [ '' ] ifNotNil: [ :v | v asString ].
	text isEmpty ifTrue: [ ^ failBlock value ].

	(service notNil and: [ service respondsTo: #evaluateCodeInCurrentFrame: ]) ifTrue: [
		raw := [ service evaluateCodeInCurrentFrame: text ] on: Error do: [ nil ].
		(raw isNil or: [ raw asString beginsWith: 'Error:' ]) ifTrue: [ ^ failBlock value ].
		^ raw
	].

	((object respondsTo: #session) and: [ object session notNil ]) ifFalse: [ ^ failBlock value ].
	session := object session.
	contextOop := (object respondsTo: #processOop)
		ifTrue: [ object processOop ]
		ifFalse: [ nil ].
	((contextOop isNumber and: [ contextOop > 20 ]) not) ifTrue: [
		contextOop := (session respondsTo: #sessionOop)
			ifTrue: [ session sessionOop ]
			ifFalse: [ 20 ]
	].
	raw := [ session executeAndFetch: text context: contextOop ] on: Error do: [ nil ].
	(raw isNil or: [ raw asString beginsWith: 'Error:' ]) ifTrue: [ ^ failBlock value ].
	^ raw
]

{ #category : 'field list' }
GbxContextInspector >> fieldList [
	| temps |
	self hasServerContextObject ifFalse: [ ^ #() ].
	temps := [ object tempNamesAndValues ] on: Error do: [ nil ].
	temps ifNil: [ ^ #() ].
	(temps respondsTo: #keys) ifTrue: [ ^ temps keys asArray ].
	(temps respondsTo: #associations) ifTrue: [ ^ (temps associations collect: [ :a | a key ]) asArray ].
	^ #()
]

{ #category : 'field list' }
GbxContextInspector >> fieldValueAtName: aName [
	| temps |
	self hasServerContextObject ifFalse: [ ^ nil ].
	temps := [ object tempNamesAndValues ] on: Error do: [ nil ].
	temps ifNil: [ ^ nil ].
	(temps respondsTo: #at:ifAbsent:) ifTrue: [ ^ temps at: aName ifAbsent: [ nil ] ].
	^ nil
]

{ #category : 'private-menu messages' }
GbxContextInspector >> copyFieldNamed: aName [
	| value |
	value := self fieldValueAtName: aName.
	value ifNil: [ ^ false ].
	Clipboard clipboardText: value asString.
	^ true
]
