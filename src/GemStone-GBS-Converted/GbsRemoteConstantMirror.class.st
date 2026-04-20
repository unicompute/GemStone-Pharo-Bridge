Class {
	#name : 'GbsRemoteConstantMirror',
	#superclass : 'Object',
	#instVars : [
		'namespaceMirror',
		'metadata'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRemoteConstantMirror class >> on: aNamespaceMirror metadata: anArray [
	^ self new
		namespaceMirror: aNamespaceMirror;
		metadata: anArray;
		yourself
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> browsableName [
	| fullName valueName constantName |
	fullName := self valueFullName.
	fullName ifNotNil: [ ^ fullName ].
	valueName := self valueName.
	valueName ifNotNil: [ ^ valueName ].
	constantName := self name.
	^ constantName
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> displayName [
	^ self name
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> hasValue [
	^ self oop notNil
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> targetDisplayName [
	| target |
	target := self browsableName.
	target ifNotNil: [ ^ target ].
	^ self valueClassName
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> targetNamespaceMirror [
	| fullName oopValue expression |
	self hasValue ifFalse: [ ^ nil ].
	fullName := self valueFullName.
	oopValue := self oop.
	oopValue ifNotNil: [
		expression := String streamContents: [ :stream |
			stream
				nextPutAll: 'System _objectForOop: ';
				nextPutAll: oopValue printString ].
		^ GbsRemoteNamespaceMirror
			on: self session
			expression: expression
			symbolListIndex: nil
			metadata: nil ].
	fullName ifNotNil: [
		^ GbsRemoteNamespaceMirror
			on: self session
			fullName: fullName ].
	^ [ self session namespaceMirrorForObject: self proxy ]
		on: Error
		do: [ :ex | nil ]
]

{ #category : 'accessing' }
GbsRemoteConstantMirror >> metadata [
	^ metadata ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRemoteConstantMirror >> metadata: anArray [
	metadata := anArray ifNil: [ #() ] ifNotNil: [ anArray asArray ]
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> name [
	^ self metadata at: 1 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteConstantMirror >> namespaceMirror [
	^ namespaceMirror
]

{ #category : 'accessing' }
GbsRemoteConstantMirror >> namespaceMirror: aNamespaceMirror [
	namespaceMirror := aNamespaceMirror
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> oop [
	^ self metadata at: 2 ifAbsent: [ nil ]
]

{ #category : 'printing' }
GbsRemoteConstantMirror >> printOn: aStream [
	super printOn: aStream.
	self name ifNotNil: [
		aStream
			nextPutAll: '(';
			nextPutAll: self name asString.
		self valueClassName ifNotNil: [
			aStream
				nextPutAll: ' : ';
				nextPutAll: self valueClassName asString ].
		aStream nextPut: $) ]
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ self session objectForOop: oopValue
]

{ #category : 'accessing' }
GbsRemoteConstantMirror >> session [
	^ namespaceMirror session
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> value [
	^ self proxy
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> valueClassName [
	^ self metadata at: 3 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> valueFullName [
	^ self metadata at: 6 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteConstantMirror >> valueName [
	^ self metadata at: 5 ifAbsent: [ nil ]
]
