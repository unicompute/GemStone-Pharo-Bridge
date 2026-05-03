Class {
	#name : 'GbsRemoteAutoloadBacktraceEntry',
	#superclass : 'Object',
	#instVars : [
		'rawLine',
		'index'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteAutoloadBacktraceEntry class >> line: aString index: anInteger [
	^ self new
		rawLine: aString;
		index: anInteger;
		yourself
]

{ #category : 'printing' }
GbsRemoteAutoloadBacktraceEntry >> displayString [
	^ self rawLine ifNil: [ '<unknown>' ] ifNotNil: [ self rawLine asString ]
]

{ #category : 'querying' }
GbsRemoteAutoloadBacktraceEntry >> fileName [
	| lineText suffix |
	lineText := self rawLine.
	lineText ifNil: [ ^ nil ].
	lineText := lineText asString.
	(lineText includes: $:) ifFalse: [ ^ nil ].
	suffix := lineText copyAfterLast: $:.
	([ suffix asInteger ] on: Error do: [ nil ]) ifNil: [ ^ nil ].
	^ lineText copyUpToLast: $:
]

{ #category : 'testing' }
GbsRemoteAutoloadBacktraceEntry >> hasLocation [
	^ self fileName notNil and: [ self lineNumber notNil ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadBacktraceEntry >> index [
	^ index ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadBacktraceEntry >> index: anInteger [
	index := anInteger
]

{ #category : 'querying' }
GbsRemoteAutoloadBacktraceEntry >> lineNumber [
	| lineText suffix |
	lineText := self rawLine.
	lineText ifNil: [ ^ nil ].
	lineText := lineText asString.
	(lineText includes: $:) ifFalse: [ ^ nil ].
	suffix := lineText copyAfterLast: $:.
	^ [ suffix asInteger ] on: Error do: [ nil ]
]

{ #category : 'printing' }
GbsRemoteAutoloadBacktraceEntry >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRemoteAutoloadBacktraceEntry >> rawLine [
	^ rawLine
]

{ #category : 'accessing' }
GbsRemoteAutoloadBacktraceEntry >> rawLine: aString [
	rawLine := aString
]
