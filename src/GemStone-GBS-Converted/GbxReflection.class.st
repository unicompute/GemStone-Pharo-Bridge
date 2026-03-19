Class {
	#name : 'GbxReflection',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'reflection' }
GbxReflection class >> withReceiver: anObject perform: aSelector withArguments: anArray [

	^ anObject perform: aSelector withArguments: anArray
]

{ #category : 'reflection' }
GbxReflection class >> identityHashOf: anObject [

	^ anObject identityHash
]

{ #category : 'reflection' }
GbxReflection class >> classOf: anObject [

	^ anObject class
]

{ #category : 'reflection' }
GbxReflection class >> basicIdentityHashOf: anObject [

	^ anObject identityHash
]

{ #category : 'reflection' }
GbxReflection class >> gbxIdentityHashOf: anObject [

	^ self
		send: #gbxIdentityHash
		to: anObject
		ifNotUnderstood: [ self identityHashOf: anObject ]
]

{ #category : 'printing' }
GbxReflection class >> debugPrint: anObject on: aStream [

	^ self
		send: #gbxDebugPrintOn:
		to: anObject
		with: aStream
		ifNotUnderstood: [ anObject printOn: aStream ]
]

{ #category : 'testing' }
GbxReflection class >> isStub: anObject [

	^ self
		send: #zzzisStub
		to: anObject
		ifNotUnderstood: [ false ]
]

{ #category : 'testing' }
GbxReflection class >> isProxy: anObject [

	^ self
		send: #gbxIsProxy
		to: anObject
		ifNotUnderstood: [ false ]
]

{ #category : 'testing' }
GbxReflection class >> shouldBeWrapped: anObject [

	^ self
		send: #gbxShouldBeWrapped
		to: anObject
		ifNotUnderstood: [ false ]
]

{ #category : 'testing' }
GbxReflection class >> isWrapped: anObject [

	^ self
		send: #gbxIsWrapped
		to: anObject
		ifNotUnderstood: [ false ]
]

{ #category : 'sending' }
GbxReflection class >> send: aSelector to: anObject with: argument ifNotUnderstood: aBlock [

	^ self
		send: aSelector
		to: anObject
		withArguments: { argument }
		ifNotUnderstood: aBlock
]

{ #category : 'sending' }
GbxReflection class >> send: aSelector to: anObject ifNotUnderstood: aBlock [

	^ self
		send: aSelector
		to: anObject
		withArguments: #()
		ifNotUnderstood: aBlock
]

{ #category : 'sending' }
GbxReflection class >> send: aSelector to: anObject withArguments: anArray ifNotUnderstood: aBlock [
	| objectClass |
	objectClass := self classOf: anObject.
	^ (objectClass canUnderstand: aSelector)
		ifTrue: [ self withReceiver: anObject perform: aSelector withArguments: anArray ]
		ifFalse: [ aBlock value ]
]
