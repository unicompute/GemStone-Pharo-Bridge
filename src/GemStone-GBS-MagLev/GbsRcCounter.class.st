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
	^ self
		executeAgainstRemote: 'obj incrementBy: amount'
		literalBindings: (Dictionary new
			at: 'amount' put: anInteger asInteger;
			yourself)
]

{ #category : 'actions' }
GbsRcCounter >> decrement [
	^ self executeAgainstRemote: 'obj decrement'
]

{ #category : 'actions' }
GbsRcCounter >> decrementBy: anInteger [
	^ self
		executeAgainstRemote: 'obj decrementBy: amount'
		literalBindings: (Dictionary new
			at: 'amount' put: anInteger asInteger;
			yourself)
]

{ #category : 'actions' }
GbsRcCounter >> decrementBy: anInteger ifLessThan: aGuardInteger then: aBlock [
	| fired |
	fired := self
		executeAgainstRemote: '| fired |
	fired := false.
	obj
		decrementBy: amount
		ifLessThan: guard
		thenExecute: [ fired := true ].
	fired'
		literalBindings: (Dictionary new
			at: 'amount' put: anInteger asInteger;
			at: 'guard' put: aGuardInteger asInteger;
			yourself).
	fired == true ifTrue: [ aBlock cull: self ].
	^ fired == true
]

{ #category : 'actions' }
GbsRcCounter >> decrementIfNegative: anInteger [
	^ self
		executeAgainstRemote: 'obj decrementIfNegative: amount'
		literalBindings: (Dictionary new
			at: 'amount' put: anInteger asInteger;
			yourself)
]

{ #category : 'converting' }
GbsRcCounter >> asInteger [
	^ self value
]
