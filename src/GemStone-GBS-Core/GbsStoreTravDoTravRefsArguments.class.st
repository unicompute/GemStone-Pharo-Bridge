Class {
	#name : 'GbsStoreTravDoTravRefsArguments',
	#superclass : 'Object',
	#instVars : [
		'storeTraversalBuffer',
		'noLongerReplicatedOops',
		'gcedOops',
		'storeTraversalFlags'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsStoreTravDoTravRefsArguments class >> storeTraversalBuffer: aBuffer noLongerReplicatedOops: noLongerOops gcedOops: gcedOopCollection flags: flagsInteger [
	^ self new
		storeTraversalBuffer: aBuffer;
		noLongerReplicatedOops: noLongerOops;
		gcedOops: gcedOopCollection;
		storeTraversalFlags: flagsInteger;
		yourself
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> clampedTravArgsByteSize [
	^ 40
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> gcedOops [
	^ gcedOops ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> gcedOops: oopCollection [
	gcedOops := oopCollection ifNil: [ #() ] ifNotNil: [ oopCollection asArray ]
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> gciPerformResultIntoRefSetFlag [
	^ 16
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> gemStoneNilOop [
	^ 20
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> minimumResultTraversalBufferBytes [
	^ 2048
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> noLongerReplicatedOops [
	^ noLongerReplicatedOops ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> noLongerReplicatedOops: oopCollection [
	noLongerReplicatedOops := oopCollection ifNil: [ #() ] ifNotNil: [ oopCollection asArray ]
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> nullExternalAddress [
	^ ExternalAddress fromAddress: 0
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> oopBufferFor: oopCollection [
	| buffer |
	oopCollection isEmpty ifTrue: [ ^ self nullExternalAddress ].
	buffer := ExternalAddress allocate: oopCollection size * self pointerSize.
	oopCollection doWithIndex: [ :oop :index |
		buffer
			integerAt: 1 + ((index - 1) * self pointerSize)
			put: oop
			size: self pointerSize
			signed: false ].
	^ buffer
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> pointerSize [
	^ 8
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> pointerValueFor: anExternalAddress [
	(anExternalAddress respondsTo: #asInteger) ifTrue: [ ^ anExternalAddress asInteger ].
	(anExternalAddress respondsTo: #asUnsignedInteger) ifTrue: [ ^ anExternalAddress asUnsignedInteger ].
	self error: 'Cannot convert external address to a native pointer value.'
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> releaseOopBuffer: anExternalAddress [
	(self pointerValueFor: anExternalAddress) = 0 ifTrue: [ ^ self ].
	anExternalAddress free.
	^ self
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> resultTraversalBufferBytes [
	^ storeTraversalBuffer nativeTraversalBufferBytes max: self minimumResultTraversalBufferBytes
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> storeTraversalBuffer [
	^ storeTraversalBuffer
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> storeTraversalBuffer: aBuffer [
	storeTraversalBuffer := aBuffer
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> storeTraversalFlags [
	^ storeTraversalFlags ifNil: [ storeTraversalBuffer flags ]
]

{ #category : 'accessing' }
GbsStoreTravDoTravRefsArguments >> storeTraversalFlags: anInteger [
	storeTraversalFlags := anInteger
]

{ #category : 'constants' }
GbsStoreTravDoTravRefsArguments >> storeTravDoArgsByteSize [
	^ 104
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> writeClampedTravArgs: ctArgs traversalBuffer: resultTraversalBuffer [
	self zeroExternalAddress: ctArgs bytes: self clampedTravArgsByteSize.
	ctArgs
		integerAt: 1 put: self gemStoneNilOop size: self pointerSize signed: false;
		integerAt: 9 put: self gemStoneNilOop size: self pointerSize signed: false;
		integerAt: 17 put: (self pointerValueFor: resultTraversalBuffer) size: self pointerSize signed: false;
		integerAt: 25 put: 0 size: 4 signed: true;
		integerAt: 29 put: 0 size: 4 signed: true;
		integerAt: 33 put: 1 size: 4 signed: true.
	^ ctArgs
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> writeStoreTravDoArgs: stdArgs storeTraversalBuffer: nativeStoreTraversalBuffer [
	self zeroExternalAddress: stdArgs bytes: self storeTravDoArgsByteSize.
	stdArgs
		integerAt: 1 put: 3 size: 4 signed: true;
		integerAt: 5 put: self gciPerformResultIntoRefSetFlag size: 4 signed: true;
		integerAt: 9 put: 0 size: 4 signed: true;
		integerAt: 13 put: 0 size: 4 signed: true;
		integerAt: 17 put: self gemStoneNilOop size: self pointerSize signed: false;
		integerAt: 81 put: (self pointerValueFor: nativeStoreTraversalBuffer) size: self pointerSize signed: false;
		integerAt: 89 put: 0 size: self pointerSize signed: false;
		integerAt: 97 put: self storeTraversalFlags size: 4 signed: true.
	^ stdArgs
]

{ #category : 'native buffers' }
GbsStoreTravDoTravRefsArguments >> withNativeBuffersOn: serverInterface do: aBlock [
	^ storeTraversalBuffer
		withNativeTraversalBufferOn: serverInterface
		do: [ :nativeStoreTraversalBuffer |
			self
				withStoreTraversalNativeBuffer: nativeStoreTraversalBuffer
				on: serverInterface
				do: aBlock ]
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> withStoreTraversalNativeBuffer: nativeStoreTraversalBuffer on: serverInterface do: aBlock [
	| stdArgs ctArgs resultTraversalBuffer noLongerBuffer gcedBuffer |
	stdArgs := ExternalAddress allocate: self storeTravDoArgsByteSize.
	ctArgs := ExternalAddress allocate: self clampedTravArgsByteSize.
	resultTraversalBuffer := serverInterface apiGciAllocTravBuf: self resultTraversalBufferBytes.
	noLongerBuffer := self oopBufferFor: self noLongerReplicatedOops.
	gcedBuffer := self oopBufferFor: self gcedOops.
	^ [
		self writeStoreTravDoArgs: stdArgs storeTraversalBuffer: nativeStoreTraversalBuffer.
		self writeClampedTravArgs: ctArgs traversalBuffer: resultTraversalBuffer.
		aBlock valueWithArguments: {
			noLongerBuffer.
			self noLongerReplicatedOops size.
			gcedBuffer.
			self gcedOops size.
			stdArgs.
			ctArgs }
	] ensure: [
		self releaseOopBuffer: noLongerBuffer.
		self releaseOopBuffer: gcedBuffer.
		serverInterface apiGciFree: resultTraversalBuffer.
		ctArgs free.
		stdArgs free ]
]

{ #category : 'private' }
GbsStoreTravDoTravRefsArguments >> zeroExternalAddress: anExternalAddress bytes: byteCount [
	1 to: byteCount do: [ :index |
		anExternalAddress unsignedByteAt: index put: 0 ].
	^ anExternalAddress
]
