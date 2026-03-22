Class {
	#name : 'GbxMethodErrorHolder',
	#superclass : 'Object',
	#instVars : [
		'remoteClass',
		'source',
		'category'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
GbxMethodErrorHolder class >> forClass: cls source: src category: cat [
	^ self new
		class: cls
		source: src
		category: cat
]

{ #category : 'initialization' }
GbxMethodErrorHolder >> class: cls source: src category: cat [
	remoteClass := cls.
	source := src ifNil: [ '' ].
	category := cat ifNil: [ 'as yet unclassified' ].
	^ self
]

{ #category : 'accessing' }
GbxMethodErrorHolder >> remoteClass [
	^ remoteClass
]

{ #category : 'accessing' }
GbxMethodErrorHolder >> category [
	^ category asSymbol
]

{ #category : 'accessing' }
GbxMethodErrorHolder >> selector [
	| line tokens selectorTokens |
	source ifNil: [ ^ #'unreadable method' ].
	line := source asString lines
		ifEmpty: [ '' ]
		ifNotEmpty: [ :lines | lines first withBlanksTrimmed ].
	line isEmpty ifTrue: [ ^ #'unreadable method' ].
	tokens := line substrings.
	tokens isEmpty ifTrue: [ ^ #'unreadable method' ].
	selectorTokens := tokens select: [ :each | each includes: $: ].
	selectorTokens ifNotEmpty: [
		^ (String streamContents: [ :stream |
			selectorTokens do: [ :each | stream nextPutAll: each ] ]) asSymbol ].
	^ tokens first asSymbol
]

{ #category : 'accessing' }
GbxMethodErrorHolder >> session [
	^ (remoteClass respondsTo: #session)
		ifTrue: [ remoteClass session ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
GbxMethodErrorHolder >> sourceText [
	^ source asString asText
]

{ #category : 'printing' }
GbxMethodErrorHolder >> displayString [
	| classText |
	classText := (remoteClass respondsTo: #remoteDescription)
		ifTrue: [ remoteClass remoteDescription ]
		ifFalse: [ remoteClass printString ].
	^ classText , ' ' , self selector asString
]

{ #category : 'updating' }
GbxMethodErrorHolder >> updateIfError: errorBlock [
	^ self
]

{ #category : 'testing' }
GbxMethodErrorHolder >> isErrorMethodHolder [
	^ true
]
