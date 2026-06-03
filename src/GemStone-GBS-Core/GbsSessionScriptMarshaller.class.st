Class {
	#name : 'GbsSessionScriptMarshaller',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionScriptMarshaller class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'marshaling' }
GbsSessionScriptMarshaller >> marshalArgumentToScript: anObject visited: visited [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', anObject oop asString, ')' ].
	anObject isInteger ifTrue: [ ^ anObject asString ].
	anObject isFloat ifTrue: [ ^ anObject printString ].
	anObject class == Fraction ifTrue: [
		^ '(', anObject numerator printString, ' / ', anObject denominator printString, ')' ].
	anObject isSymbol ifTrue: [ ^ '#', anObject asString ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject ifNil: [ ^ 'nil' ].
	anObject isCharacter ifTrue: [
		^ '(Character value: ', anObject asInteger printString, ')' ].
	anObject isString ifTrue: [ ^ session marshalStringLiteralToScript: anObject ].
	^ [ session marshalComplexArgumentToScript: anObject visited: visited ]
		on: Error
		do: [ :ex |
			self error: ((ex messageText ifNil: [ ex printString ]) asString withBlanksTrimmed),
				' Argument class: ', anObject class name ]
]

{ #category : 'accessing' }
GbsSessionScriptMarshaller >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionScriptMarshaller >> session: aSession [
	session := aSession
]
