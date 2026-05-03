Class {
	#name : 'GbsRcQueue',
	#superclass : 'GbsMaglevRuntimeProxy',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'mutating' }
GbsRcQueue >> add: anObject [
	| result |
	result := self executeAgainstRemote: 'obj add: ', (session marshalArgumentToScript: anObject).
	^ session materializeMaglevRuntimeValue: result
]

{ #category : 'querying' }
GbsRcQueue >> asArray [
	| items |
	items := self executeAgainstRemote: '| values |
	values := OrderedCollection new.
	(obj respondsTo: #do:)
		ifTrue: [ obj do: [ :each | values add: each ] ].
	values asArray'.
	items ifNil: [ ^ #() ].
	^ items collect: [ :each | session materializeMaglevRuntimeValue: each ]
]

{ #category : 'querying' }
GbsRcQueue >> first [
	^ self peek
]

{ #category : 'querying' }
GbsRcQueue >> isEmpty [
	^ self executeAgainstRemote: 'obj isEmpty'
]

{ #category : 'querying' }
GbsRcQueue >> peek [
	| result |
	result := self executeAgainstRemote: 'obj peek'.
	^ session materializeMaglevRuntimeValue: result
]

{ #category : 'mutating' }
GbsRcQueue >> remove [
	| result |
	result := self executeAgainstRemote: 'obj remove'.
	^ session materializeMaglevRuntimeValue: result
]

{ #category : 'mutating' }
GbsRcQueue >> removeAll [
	^ self executeAgainstRemote: 'obj removeAll'
]

{ #category : 'querying' }
GbsRcQueue >> size [
	^ self executeAgainstRemote: 'obj size'
]
