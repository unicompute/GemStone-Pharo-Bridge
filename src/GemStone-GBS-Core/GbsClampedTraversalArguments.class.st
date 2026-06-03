Class {
	#name : 'GbsClampedTraversalArguments',
	#superclass : 'Object',
	#instVars : [
		'clampSpecOop',
		'traversalBuffer',
		'traversalLevel',
		'retrievalFlags',
		'isRpc'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsClampedTraversalArguments class >> clampSpecOop: clampOop traversalBuffer: aTraversalBuffer level: anInteger retrievalFlags: flagsInteger [
	^ self new
		clampSpecOop: clampOop;
		traversalBuffer: aTraversalBuffer;
		traversalLevel: anInteger;
		retrievalFlags: flagsInteger;
		isRpc: true;
		yourself
]

{ #category : 'constants' }
GbsClampedTraversalArguments >> byteSize [
	^ 40
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> clampSpecOop [
	^ clampSpecOop
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> clampSpecOop: anInteger [
	clampSpecOop := anInteger
]

{ #category : 'constants' }
GbsClampedTraversalArguments >> gemStoneNilOop [
	^ 20
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> isRpc [
	^ isRpc ifNil: [ true ]
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> isRpc: aBoolean [
	isRpc := aBoolean
]

{ #category : 'constants' }
GbsClampedTraversalArguments >> pointerSize [
	^ 8
]

{ #category : 'private' }
GbsClampedTraversalArguments >> pointerValueFor: anExternalAddress [
	(anExternalAddress respondsTo: #asInteger) ifTrue: [ ^ anExternalAddress asInteger ].
	(anExternalAddress respondsTo: #asUnsignedInteger) ifTrue: [ ^ anExternalAddress asUnsignedInteger ].
	self error: 'Cannot convert external address to a native pointer value.'
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> retrievalFlags [
	^ retrievalFlags ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> retrievalFlags: anInteger [
	retrievalFlags := anInteger
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> traversalBuffer [
	^ traversalBuffer
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> traversalBuffer: anExternalAddress [
	traversalBuffer := anExternalAddress
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> traversalLevel [
	^ traversalLevel ifNil: [ 1 ]
]

{ #category : 'accessing' }
GbsClampedTraversalArguments >> traversalLevel: anInteger [
	traversalLevel := anInteger
]

{ #category : 'native buffers' }
GbsClampedTraversalArguments >> withNativeBufferDo: aBlock [
	| buffer |
	buffer := ExternalAddress allocate: self byteSize.
	^ [
		self writeTo: buffer.
		aBlock value: buffer
	] ensure: [ buffer free ]
]

{ #category : 'native buffers' }
GbsClampedTraversalArguments >> writeTo: anExternalAddress [
	self zeroExternalAddress: anExternalAddress bytes: self byteSize.
	anExternalAddress
		integerAt: 1 put: self clampSpecOop size: self pointerSize signed: false;
		integerAt: 9 put: self gemStoneNilOop size: self pointerSize signed: false;
		integerAt: 17 put: (self pointerValueFor: self traversalBuffer) size: self pointerSize signed: false;
		integerAt: 25 put: self traversalLevel size: 4 signed: true;
		integerAt: 29 put: self retrievalFlags size: 4 signed: true;
		integerAt: 33 put: (self isRpc ifTrue: [ 1 ] ifFalse: [ 0 ]) size: 4 signed: true.
	^ anExternalAddress
]

{ #category : 'private' }
GbsClampedTraversalArguments >> zeroExternalAddress: anExternalAddress bytes: byteCount [
	1 to: byteCount do: [ :index |
		anExternalAddress unsignedByteAt: index put: 0 ].
	^ anExternalAddress
]
