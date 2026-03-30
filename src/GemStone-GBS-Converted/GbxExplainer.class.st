Class {
	#name : 'GbxExplainer',
	#superclass : 'Object',
	#instVars : [
		'class',
		'context',
		'explainee',
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxExplainer class >> explain: aString class: aClass selector: aSelector methodText: fullText for: anApplicationModel [
	| explainer serverContext explanation |
	serverContext := (anApplicationModel notNil and: [ anApplicationModel respondsTo: #context ])
		ifTrue: [ anApplicationModel context ]
		ifFalse: [ nil ].
	(serverContext isNil or: [
		(serverContext respondsTo: #gbxIsServerContext)
			ifTrue: [ serverContext gbxIsServerContext not ]
			ifFalse: [ true ] ]) ifTrue: [
		^ aString isEmpty
			ifTrue: [ 'Need to select some text' ]
			ifFalse: [ 'GemStone cannot explain that' ] ].
	explainer := self new.
	explanation := aString isEmpty
		ifTrue: [ 'Need to select some text' ]
		ifFalse: [
			explainer
				session: ((serverContext respondsTo: #session) ifTrue: [ serverContext session ] ifFalse: [ nil ]);
				context: serverContext;
				class: aClass;
				explainee: aString trimBoth;
				explain ].
	^ explanation
]

{ #category : 'accessing' }
GbxExplainer >> class: aBehavior [
	class := aBehavior
]

{ #category : 'accessing' }
GbxExplainer >> context: aServerContext [
	context := aServerContext
]

{ #category : 'explaining' }
GbxExplainer >> explain [
	| results |
	results := OrderedCollection new.
	{ self explainSelf.
	  self explainClass.
	  self explainSelectors.
	  self explainContextSelector.
	  self explainInteger.
	  self explainFloat.
	  self explainFraction } do: [ :each |
		each ifNotNil: [ results add: each ] ].
	results isEmpty ifTrue: [ ^ 'GemStone cannot explain that' ].
	^ String streamContents: [ :stream |
		results do: [ :each |
			stream nextPutAll: each.
			stream cr ] ]
]

{ #category : 'explaining' }
GbxExplainer >> explainClass [
	(session isNil or: [ explainee isEmpty ]) ifTrue: [ ^ nil ].
	[
		| answer |
		answer := session executeAndFetch: '[
			| name |
			name := ''', explainee, '''.
			(System myUserProfile symbolList anySatisfy: [ :dict | dict includesKey: name asSymbol ])
				ifTrue: [ name ]
				ifFalse: [ nil ]
		] value'.
		(answer isNil or: [ answer = 'nil' ]) ifTrue: [ ^ nil ].
		^ '#', explainee, ' is a class on the server'
	] on: Error do: [ nil ]
]

{ #category : 'explaining' }
GbxExplainer >> explainContextSelector [
	(class isNil or: [ explainee isEmpty ]) ifTrue: [ ^ nil ].
	(class respondsTo: #canUnderstand:) ifFalse: [ ^ nil ].
	^ (class canUnderstand: explainee asSymbol)
		ifTrue: [ '#', explainee, ' is a selector in ', class name asString ]
		ifFalse: [ nil ]
]

{ #category : 'explaining' }
GbxExplainer >> explainFloat [
	(explainee includes: $.) ifFalse: [ ^ nil ].
	^ self explainNumberNamed: 'Float' using: [ explainee asNumber ]
]

{ #category : 'explaining' }
GbxExplainer >> explainFraction [
	(explainee includes: $/) ifFalse: [ ^ nil ].
	^ self explainNumberNamed: 'Fraction' using: [
		| parts |
		parts := explainee substrings: '/'.
		parts size = 2 ifFalse: [ self error: 'not fraction' ].
		(parts first asNumber) / (parts second asNumber) ]
]

{ #category : 'explaining' }
GbxExplainer >> explainInteger [
	^ self explainNumberNamed: 'Integer' using: [ explainee asInteger ]
]

{ #category : 'explaining' }
GbxExplainer >> explainNumberNamed: kind using: aBlock [
	^ [ aBlock value. explainee, ' is a ', kind, ' on the server' ]
		on: Error
		do: [ nil ]
]

{ #category : 'explaining' }
GbxExplainer >> explainSelectors [
	(session isNil or: [ explainee isEmpty ]) ifTrue: [ ^ nil ].
	[
		| answer |
		answer := session executeAndFetch: '[
			| selector count |
			selector := #', explainee, '.
			count := 0.
			System myUserProfile symbolList do: [ :dict |
				dict valuesDo: [ :value |
					(value isBehavior and: [ value canUnderstand: selector ])
						ifTrue: [ count := count + 1 ] ] ].
			count
		] value'.
		(answer isNil or: [ answer = 'nil' or: [ answer = '0' ] ]) ifTrue: [ ^ nil ].
		^ '#', explainee, ' is a selector in ', answer asString, ' classes on the server'
	] on: Error do: [ nil ]
]

{ #category : 'explaining' }
GbxExplainer >> explainSelf [
	explainee = 'self' ifFalse: [ ^ nil ].
	(session isNil or: [ context isNil ]) ifTrue: [ ^ 'self is the current receiver on server' ].
	[
		| contextOop description |
		contextOop := (context respondsTo: #processOop)
			ifTrue: [ context processOop ]
			ifFalse: [ 20 ].
		description := session executeAndFetch: 'self printString' context: contextOop.
		(description isNil or: [ description = 'nil' ])
			ifTrue: [ ^ 'self is the current receiver on server' ].
		^ 'self is ', description, ' on server'
	] on: Error do: [ 'self is the current receiver on server' ]
]

{ #category : 'accessing' }
GbxExplainer >> explainee: anObject [
	explainee := anObject asString
]

{ #category : 'accessing' }
GbxExplainer >> session: aSession [
	session := aSession
]
