Class {
	#name : 'GbsRemoteAutoloadMirror',
	#superclass : 'Object',
	#instVars : [
		'namespaceMirror',
		'metadata'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRemoteAutoloadMirror class >> on: aNamespaceMirror metadata: anArray [
	^ self new
		namespaceMirror: aNamespaceMirror;
		metadata: anArray;
		yourself
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> autoloadFile [
	^ self metadata at: 2 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> constantMirror [
	^ namespaceMirror
		constantMirrorAt: self name
		ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> displayName [
	^ self name
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> isLoaded [
	^ self rawState == true
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> isLoading [
	^ self rawState isNil
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> oop [
	^ self metadata at: 4 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> metadata [
	^ metadata ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> metadata: anArray [
	metadata := anArray ifNil: [ #() ] ifNotNil: [ anArray asArray ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> name [
	^ self metadata at: 1 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> namespaceMirror [
	^ namespaceMirror
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> namespaceMirror: aNamespaceMirror [
	namespaceMirror := aNamespaceMirror
]

{ #category : 'printing' }
GbsRemoteAutoloadMirror >> printOn: aStream [
	super printOn: aStream.
	self name ifNotNil: [
		aStream
			nextPutAll: '(';
			nextPutAll: self name asString.
		self autoloadFile ifNotNil: [
			aStream
				nextPutAll: ' -> ';
				nextPutAll: self autoloadFile asString ].
		aStream
			nextPutAll: ' ';
			nextPutAll: self stateLabel asString;
			nextPut: $) ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ self session objectForOop: oopValue
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> rawState [
	^ self metadata at: 3 ifAbsent: [ false ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> session [
	^ namespaceMirror session
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> stateLabel [
	self isLoaded ifTrue: [ ^ 'Loaded' ].
	self isLoading ifTrue: [ ^ 'Loading' ].
	^ 'Pending'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> targetDisplayName [
	| constantMirror |
	constantMirror := self constantMirror.
	constantMirror ifNil: [ ^ nil ].
	(constantMirror hasValue and: [ self isLoaded ]) ifFalse: [ ^ nil ].
	^ constantMirror targetDisplayName
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> valueClassName [
	| constantMirror |
	constantMirror := self constantMirror.
	constantMirror ifNil: [ ^ nil ].
	(constantMirror hasValue and: [ self isLoaded ]) ifFalse: [ ^ nil ].
	^ constantMirror valueClassName
]
