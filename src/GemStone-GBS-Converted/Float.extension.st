Extension { #name : #'Float' }

{ #category : '*GemStone-GBS-Converted-GBS-private' }
Float class >> gbsReplicatorClass [

	^GbxFloatReplicator
]

{ #category : '*GemStone-GBS-Converted-private-GBS-extensions' }
Float class >> newFromGSObjectReport: aGSObjectReport [
	"Private.  GBS."

	| inst |
	inst := aGSObjectReport copyBytes.
	inst changeClassTo: self.
	Float ieeePrimitivesEnabled
		ifFalse: [GbsSessionManager current checkFloat: inst].
	^inst
]

{ #category : '*GemStone-GBS-Converted-private-GBS-extensions' }
Float class >> raise: signalName receiver: anObject selector: aSymbol arg: anArg errorString: aMessage [
	"Private.  GBS.  Some Float and Float primitives may fail because their argument is a stub that didn't get faulted before the primitive was entered.  If that causes control to reach this method, the stub will have faulted by now.  Re-dispatch the message."

	^thisContext gbxHasRecursed
		ifTrue: [ super
			raise: signalName
			receiver: anObject
			selector: aSymbol
			arg: anArg
			errorString: aMessage ]
		ifFalse: [ anObject perform: aSymbol with: anArg ]
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
Float class >> gbsByteSwizzleStride [

	^3	"8-byte swizzling"
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Float >> gbxCanTraversalSplit [
	"Private. Answer true if it is okay to split any indexed
	instance variables across multiple traversal buffers.
	True for most objects, overridden for the few classes
	that must be traversed atomically.

	Floats are stored big-endian on the server, so on
	little-endian platforms the C layer must swizzle the
	bytes, which requires them to be in the same buffer.
	Floats are small, so no advantage in splitting anyway."

	^ false.
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Float >> gbxIsServerSpecialInSession: aSession [
	"Sender must hold sessionProtect"

	^aSession isSpecialDouble: self
]

{ #category : '*GemStone-GBS-Converted-private-GBS-extensions' }
Float >> asGSObjectInSession: aGbsSession [
	"Private.  GBS.  Given the Smalltalk object <self>, find an existing or create a new corresponding delegate."
	"If the receiver's value is in range to be a server SmallFloat64, answer that. Otherwise, answer a cached 
	POM oop delegate."

	| del |
	del := aGbsSession
				sessionCritical: [aGbsSession delegateForSpecialDouble: self].
	^del isNil ifTrue: [super asGSObjectInSession: aGbsSession] ifFalse: [del]
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Float class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Float class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Float class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Float >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Float >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Float >> isRunningUnderAssertingVM [
	^false
]

