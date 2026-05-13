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
	fired := (GbsRemoteCommand
		blockBody: '| counter fired |
	counter := System sharedCounter: arg1.
	fired := false.
	counter
		decrementBy: arg2
		ifLessThan: arg3
		thenExecute: [ fired := true ].
	fired'
		literalArguments: { index asInteger. anInteger asInteger. aGuardInteger asInteger })
		executeAndFetchObjectIn: session.
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
