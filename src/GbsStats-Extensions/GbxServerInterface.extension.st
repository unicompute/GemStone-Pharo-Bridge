Extension { #name : 'GbxServerInterface' }

{ #category : '*GbsStats-Extensions' }
GbxServerInterface >> statResource: aStatResource
[
	"If aStatResource is nil, return a non-wrapped GbxCInterface.  Otherwise, 
	 return a GbxCInterfaceWithStats-wrapped cinterface."

	^aStatResource isNil 
		ifTrue: [self]
		ifFalse: 
			[GbxServerInterfaceWithStats serverInterface: self
				statResource: aStatResource]
]

{ #category : '*GbsStats-Extensions' }
GbxServerInterface class >> disableStats
[
	"First, make sure PrimInterface is initialized"

	GbxGciCallSequencer primInterface
]

{ #category : '*GbsStats-Extensions' }
GbxServerInterface class >> enableStats
[
	"Make sure PrimInterface is initialized. This may not be needed."

	GBSM serverInterface callSequencer primInterface
]

