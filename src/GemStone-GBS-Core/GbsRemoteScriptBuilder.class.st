Class {
	#name : 'GbsRemoteScriptBuilder',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'convenience' }
GbsRemoteScriptBuilder class >> literalFor: anObject [
	^ self new literalFor: anObject
]

{ #category : 'convenience' }
GbsRemoteScriptBuilder class >> objectForOop: anInteger [
	^ self new objectForOop: anInteger
]

{ #category : 'convenience' }
GbsRemoteScriptBuilder class >> send: aSelector to: receiverScript arguments: argumentCollection [
	^ self new
		send: aSelector
		to: receiverScript
		arguments: argumentCollection
]

{ #category : 'literals' }
GbsRemoteScriptBuilder >> collectionLiteralFor: aCollection [
	^ String streamContents: [ :stream |
		stream nextPutAll: '{ '.
		aCollection doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPutAll: '. ' ].
			stream nextPutAll: (self literalFor: each) ].
		stream nextPutAll: ' }' ]
]

{ #category : 'literals' }
GbsRemoteScriptBuilder >> literalFor: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	(anObject isKindOf: GbsProxy)
		ifTrue: [ ^ self objectForOop: anObject oop ].
	anObject isSymbol ifTrue: [ ^ self literalForSymbol: anObject ].
	anObject isString ifTrue: [ ^ self literalForString: anObject ].
	anObject isNumber ifTrue: [ ^ anObject printString ].
	((anObject respondsTo: #oop) and: [ anObject oop isInteger ])
		ifTrue: [ ^ self objectForOop: anObject oop ].
	(anObject isArray or: [ anObject isKindOf: OrderedCollection ])
		ifTrue: [ ^ self collectionLiteralFor: anObject ].
	self error: 'Unsupported remote script literal: ', anObject class name
]

{ #category : 'literals' }
GbsRemoteScriptBuilder >> literalForString: aString [
	| quote escaped |
	quote := String with: $'.
	escaped := aString asString
		copyReplaceAll: quote
		with: quote , quote.
	^ quote , escaped , quote
]

{ #category : 'literals' }
GbsRemoteScriptBuilder >> literalForSymbol: aSymbol [
	^ '(' , (self literalForString: aSymbol asString) , ' asSymbol)'
]

{ #category : 'references' }
GbsRemoteScriptBuilder >> objectForOop: anInteger [
	^ '(Object _objectForOop: ', anInteger asInteger printString, ')'
]

{ #category : 'messages' }
GbsRemoteScriptBuilder >> send: aSelector to: receiverScript arguments: argumentCollection [
	| selector arguments argCount keywords |
	selector := aSelector asSymbol.
	arguments := argumentCollection asArray.
	argCount := selector numArgs.
	arguments size = argCount
		ifFalse: [
			self
				error: 'Selector ', selector asString, ' expects ',
					argCount printString, ' arguments, got ',
					arguments size printString ].
	argCount = 0
		ifTrue: [ ^ receiverScript , ' ' , selector asString ].
	(selector asString includes: $:) ifFalse: [
		^ receiverScript , ' ' , selector asString , ' ' , (self literalFor: arguments first) ].
	keywords := selector asString findTokens: ':'.
	^ String streamContents: [ :stream |
		stream nextPutAll: receiverScript.
		1 to: keywords size do: [ :index |
			stream
				space;
				nextPutAll: (keywords at: index);
				nextPut: $:;
				space;
				nextPutAll: (self literalFor: (arguments at: index)) ] ]
]
