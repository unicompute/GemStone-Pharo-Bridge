Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstArgumentPrintOn: aStream [
	self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstMessenger [
	^ CstMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxDebugPrintOn: aStream [
	self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxIsForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxIsStub [
	^ false
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxIsWrapped [
	^ false
]
