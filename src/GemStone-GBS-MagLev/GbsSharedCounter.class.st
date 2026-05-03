Class {
	#name : 'GbsSharedCounter',
	#superclass : 'Object',
	#instVars : [
		'session',
		'index'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsSharedCounter class >> on: aSession index: anInteger [
	^ self new
		session: aSession;
		index: anInteger;
		yourself
]

{ #category : 'querying' }
GbsSharedCounter >> value [
	^ session sharedCounterAt: index
]

{ #category : 'mutating' }
GbsSharedCounter >> value: anInteger [
	^ session sharedCounterAt: index put: anInteger
]

{ #category : 'mutating' }
GbsSharedCounter >> increment [
	^ self incrementBy: 1
]

{ #category : 'mutating' }
GbsSharedCounter >> incrementBy: anInteger [
	^ session incrementSharedCounterAt: index by: anInteger
]

{ #category : 'mutating' }
GbsSharedCounter >> decrement [
	^ self decrementBy: 1
]

{ #category : 'mutating' }
GbsSharedCounter >> decrementBy: anInteger [
	^ session decrementSharedCounterAt: index by: anInteger
]

{ #category : 'mutating' }
GbsSharedCounter >> decrementBy: anInteger ifLessThan: aGuardInteger then: aBlock [
	| fired |
	fired := session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: '| counter fired |
	counter := System sharedCounter: ';
			nextPutAll: index printString;
			nextPutAll: '.
	fired := false.
	counter
		decrementBy: ';
			nextPutAll: anInteger asInteger printString;
			nextPutAll: '
		ifLessThan: ';
			nextPutAll: aGuardInteger asInteger printString;
			nextPutAll: '
		thenExecute: [ fired := true ].
	fired' ]).
	fired == true ifTrue: [ aBlock cull: self ].
	^ fired == true
]

{ #category : 'accessing' }
GbsSharedCounter >> index [
	^ index
]

{ #category : 'accessing' }
GbsSharedCounter >> index: anInteger [
	index := anInteger asInteger
]

{ #category : 'printing' }
GbsSharedCounter >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(index=';
		nextPutAll: index printString;
		nextPutAll: ' value=';
		nextPutAll: self value printString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsSharedCounter >> session [
	^ session
]

{ #category : 'accessing' }
GbsSharedCounter >> session: aSession [
	session := aSession
]
