Extension { #name : 'Semaphore' }

{ #category : '*GbsStats-Extensions' }
Semaphore >> statAdaptor: aStatAdaptorOrNil
[
	"Return a GbxSemaphoreWithStats wrapping the receiver, if aStatAdaptorOrNil 
	 is non-nil - stats are being enabled.  If it's nil, return self - stats are already 
	 disabled."

	^aStatAdaptorOrNil isNil 
		ifTrue: [self]
		ifFalse: 
			[^GemStone.Gbs.GbxSemaphoreWithStats semaphore: self
				statAdaptor: aStatAdaptorOrNil]
]

