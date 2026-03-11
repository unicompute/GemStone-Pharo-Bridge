Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstMessenger [
	^ CstMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstArgumentPrintOn: aStream [
	self printOn: aStream
]
