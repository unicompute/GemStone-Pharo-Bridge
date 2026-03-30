Class {
	#name : 'GbxReflection',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxReflection class >> basicIdentityHashOf: anObject [
	^ anObject identityHash
]

{ #category : 'accessing' }
GbxReflection class >> classOf: anObject [
	^ anObject class
]

{ #category : 'printing' }
GbxReflection class >> debugPrint: anObject on: aStream [
	(anObject respondsTo: #gbxDebugPrintOn:)
		ifTrue: [ anObject gbxDebugPrintOn: aStream ]
		ifFalse: [ anObject printOn: aStream ]
]

{ #category : 'accessing' }
GbxReflection class >> gbxIdentityHashOf: anObject [
	(anObject respondsTo: #gbxIdentityHash)
		ifTrue: [ ^ anObject gbxIdentityHash ].
	^ self identityHashOf: anObject
]

{ #category : 'accessing' }
GbxReflection class >> identityHashOf: anObject [
	^ anObject identityHash
]

{ #category : 'testing' }
GbxReflection class >> isStub: anObject [
	^ anObject respondsTo: #gbxIsStub
		and: [ anObject gbxIsStub ]
]

{ #category : 'testing' }
GbxReflection class >> isWrapped: anObject [
	^ anObject respondsTo: #gbxIsWrapped
		and: [ anObject gbxIsWrapped ]
]

{ #category : 'message sending' }
GbxReflection class >> withReceiver: anObject perform: aSelector withArguments: anArray [
	^ anObject perform: aSelector withArguments: anArray
]
