Class {
	#name : 'GbxLimitingStream',
	#superclass : 'GbxDumpingStream',
	#instVars : [
		'indentLevel',
		'maxSize',
		'size'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
GbxLimitingStream >> close
[
	^ (stream respondsTo: #close)
		ifTrue: [ stream close ]
		ifFalse: [ self ]
]

{ #category : 'accessing' }
GbxLimitingStream >> indentLevel
[
	^ indentLevel
]

{ #category : 'accessing' }
GbxLimitingStream >> indentLess
[
	indentLevel := indentLevel - 1.
	indentLevel < 0 ifTrue: [ self error: 'Indent level less than 0' ].
	^ indentLevel
]

{ #category : 'accessing' }
GbxLimitingStream >> indentMore
[
	indentLevel := indentLevel + 1.
	^ indentLevel
]

{ #category : 'accessing' }
GbxLimitingStream >> maxSize
[
	^ maxSize
]

{ #category : 'accessing' }
GbxLimitingStream >> maxSize: anInteger
[
	maxSize := anInteger.
	^ self
]

{ #category : 'accessing' }
GbxLimitingStream >> nextPut: anObject
[
	size >= maxSize ifTrue: [ self signalMaxSizeReached ].
	size := size + 1.
	stream nextPut: anObject.
	anObject = Character cr ifTrue: [ self indent ].
	^ anObject
]

{ #category : 'accessing' }
GbxLimitingStream >> nextPutAllText: aText
[
	| proposedIncrease |
	proposedIncrease := aText size.
	size + proposedIncrease >= maxSize
		ifTrue: [ self signalMaxSizeReached ].
	size := size + proposedIncrease.
	(stream respondsTo: #nextPutAllText:)
		ifTrue: [ stream nextPutAllText: aText ]
		ifFalse: [ stream nextPutAll: aText asString ].
	^ aText
]

{ #category : 'accessing' }
GbxLimitingStream >> position
[
	^ size
]

{ #category : 'accessing' }
GbxLimitingStream >> printClientHeaderFor: anObject
[
	self nextPutAll: 'client'.
	((anObject respondsTo: #isImmutable) and: [ anObject isImmutable ])
		ifTrue: [ self nextPutAll: ' (immutable)' ].
	self nextPutAll: ' = '
]

{ #category : 'accessing' }
GbxLimitingStream >> printUnknownClientHeader
[
	self nextPutAll: 'client = '
]

{ #category : 'accessing' }
GbxLimitingStream >> size
[
	^ size
]

{ #category : 'private' }
GbxLimitingStream >> signalMaxSizeReached
[
	((Smalltalk at: #GbsMaxStreamSizeNotification ifAbsent: [ Notification ])
		respondsTo: #raiseSignal)
		ifTrue: [ (Smalltalk at: #GbsMaxStreamSizeNotification ifAbsent: [ Notification ]) raiseSignal ]
		ifFalse: [ Notification signal ]
]

{ #category : 'debugging' }
GbxLimitingStream >> indent
[
	indentLevel timesRepeat: [ self nextPut: Character tab ]
]

{ #category : 'initialize-release' }
GbxLimitingStream >> initialize
[
	super initialize.
	indentLevel := 0.
	size := 0.
	maxSize := 1000000.
	^ self
]

{ #category : 'testing' }
GbxLimitingStream >> canQuery: aSemaphoreLike
[
	aSemaphoreLike ifNil: [ ^ false ].
	^ [ aSemaphoreLike critical: [ true ] unlessBlocked: [ false ] ]
		on: Error
		do: [ false ]
]

{ #category : 'testing' }
GbxLimitingStream >> canQueryServerSession: aSession
[
	| sessionProtect gciProtect clientMapProtect |
	aSession ifNil: [ ^ false ].
	sessionProtect := [ aSession sessionProtect ] on: Error do: [ nil ].
	gciProtect := [
		(Smalltalk at: #GbxGciCallSequencer ifAbsent: [ nil ])
			ifNotNil: [ :cls | cls gciCallProtect ] ]
		on: Error
		do: [ nil ].
	clientMapProtect := [
		(Smalltalk at: #GBSM ifAbsent: [ nil ])
			ifNotNil: [ :manager | manager clientMap writeProtect ] ]
		on: Error
		do: [ nil ].
	^ (self canQuery: sessionProtect)
		and: [
			(self canQuery: gciProtect)
				and: [ self canQuery: clientMapProtect ] ]
]

{ #category : 'testing' }
GbxLimitingStream >> canQueryStObjCache
[
	^ true
]
