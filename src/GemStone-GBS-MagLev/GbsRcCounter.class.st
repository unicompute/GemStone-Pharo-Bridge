Class {
	#name : 'GbsRcCounter',
	#superclass : 'GbsMaglevRuntimeProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'querying' }
GbsRcCounter >> value [
	^ self executeAgainstRemote: 'obj value'
]

{ #category : 'actions' }
GbsRcCounter >> increment [
	^ self executeAgainstRemote: 'obj increment'
]

{ #category : 'actions' }
GbsRcCounter >> incrementBy: anInteger [
	^ self executeAgainstRemote: 'obj incrementBy: ', anInteger asInteger printString
]

{ #category : 'actions' }
GbsRcCounter >> decrement [
	^ self executeAgainstRemote: 'obj decrement'
]

{ #category : 'actions' }
GbsRcCounter >> decrementBy: anInteger [
	^ self executeAgainstRemote: 'obj decrementBy: ', anInteger asInteger printString
]

{ #category : 'actions' }
GbsRcCounter >> decrementBy: anInteger ifLessThan: aGuardInteger then: aBlock [
	| fired |
	fired := self executeAgainstRemote: (String streamContents: [ :stream |
		stream
			nextPutAll: '| fired |
	fired := false.
	obj
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

{ #category : 'actions' }
GbsRcCounter >> decrementIfNegative: anInteger [
	^ self executeAgainstRemote: 'obj decrementIfNegative: ', anInteger asInteger printString
]

{ #category : 'converting' }
GbsRcCounter >> asInteger [
	^ self value
]
