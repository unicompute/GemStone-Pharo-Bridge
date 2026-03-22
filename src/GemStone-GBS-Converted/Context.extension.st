Extension { #name : #'Context' }

{ #category : '*GemStone-GBS-Converted-private-debugger' }
Context >> gbxIsServerCallContext [
	"Private.  GBS.
	One context on the client stack must uniquely identify a send into the server.
	This is the block in GbxServerInteraction>>privateExecute that does the looping continue.
	There are two blocks in that method, we only want the first one."

	true ifFalse: [GbsSession dependsOnStructureOfServerCall].
	"The above marker is so we can find dependencies should we need to change
	GbxServerInteraction>>privateExecute."
	^ self mclass == GbxServerInteraction
		and: [
			(self gbxSelector = #privateExecute and: [ self isBlockContext ])
				and: [
					| homeMethod firstNestedBlock |
					homeMethod := self method homeMethod.
					firstNestedBlock := homeMethod literals
						detect: [ :each | each isCompiledBlock ]
						ifNone: [ nil ].
					self method == firstNestedBlock ] ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Context >> gbxIsServerContext [
	"Answer true if the receiver represents a GemStone server 
	execution context, false if it represents a client execution context."

	^false
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> gbxSelector [
	"Private.  GBS.  Return the selector for the receiver."

	^self selector
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> gbxIsGsTopGlue [
	"Private.  GBS."

	| thisReceiver |
	thisReceiver := self homeReceiver.
	^GbsStackDumper
		ifUnderstoodSend: #gbxIsGsTopGlue:
		to: thisReceiver
		arguments: (Array with: self gbxSelector)
		else: [false]
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> gbxHasRecursed [
	"Private.  GBS.  Return true if this context's method is on the stack more than once.  This doesn't work if called from within a block."

	| ctx |
	ctx := self "home" sender.
	[ ctx notNil and: [ ctx method ~= method ]]
		whileTrue: [ "Search for a context on our method"
			ctx := ctx sender ].
	^ctx notNil
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> gbxIsGsBottomGlue [
	"Private.  GBS."

	| thisReceiver |
	thisReceiver := self homeReceiver.
	^GbsStackDumper
		ifUnderstoodSend: #gbxIsGsBottomGlue:
		to: thisReceiver
		arguments: (Array with: self gbxSelector)
		else: [false]
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> gbxPeekForReceiver [
	"Private.  GBS.  Return the receiver of the pending message send."

	| s objs rcvrIndex |
	s := self peekForSelector.
	s isNil ifTrue: [^nil].
	rcvrIndex := s numArgs + 1.
	objs := self messageObjects.
	^objs size < rcvrIndex ifTrue: [nil] ifFalse: [objs at: rcvrIndex]
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> makeSelectorBold: text [

	text makeSelectorBoldIn: self mclass
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> homeReceiver [
	"VisualWorks compatibility. For Pharo method and block contexts the
	receiver already matches the home receiver needed by the debugger."

	(self respondsTo: #home)
		ifTrue: [
			| home |
			home := self home.
			home ifNotNil: [ ^ home receiver ] ].
	^ self receiver
]

{ #category : '*GemStone-GBS-Converted-GBS-private-extensions' }
Context >> mclass [
	"VisualWorks compatibility. The debugger expects a local client context
	to answer the class that owns the executing method."

	| localMethodClass homeReceiver |
	localMethodClass := self methodClass.
	localMethodClass ifNotNil: [ ^ localMethodClass ].
	(self method respondsTo: #methodClass) ifTrue: [
		localMethodClass := self method methodClass.
		localMethodClass ifNotNil: [ ^ localMethodClass ] ].
	homeReceiver := self homeReceiver.
	^ homeReceiver
		ifNil: [ Object ]
		ifNotNil: [ homeReceiver class ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Context >> gbxIsGsGlue [
	"Private. GBS."

	"Test whether the receiver is part of GBS mechanisms for sending to the 
	GemStone server and handling returned objects, exceptions, and the like."

	^self gbxIsGsTopGlue or: [self gbxIsGsBottomGlue]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Context >> gbxIsInStackOf: topContext [
	"Answer true if I am part of the stack identified by topContext."

	^topContext hasSender: self
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Context class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Context class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Context class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Context >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Context >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Context >> isRunningUnderAssertingVM [
	^false
]
