Class {
	#name : 'GbxKernelPomOop',
	#superclass : 'GbxKernelOop',
	#instVars : [
		'oopNumber'
	],
	#classVars : [
		'LastKernelOopNumber',
		'OAbstractDictionary',
		'OAbstractException',
		'OAdmonition',
		'OAlmostOutOfMemory',
		'OAlmostOutOfStack',
		'OArgumentError',
		'OArgumentTypeError',
		'OArray',
		'OAssociation',
		'OBag',
		'OBehavior',
		'OBlockClosure',
		'OBoolean',
		'OBreak',
		'OBreakpoint',
		'OByteArray',
		'OCannotReturn',
		'OCharacter',
		'OCharacterCollection',
		'OClampSpecification',
		'OClampSpecificationOLD',
		'OClass',
		'OClassOrganizer',
		'OClassSet',
		'OClientForwarder',
		'OClientForwarderSend',
		'OCollection',
		'OCompileError',
		'OComplexBlock',
		'OComplexVCBlock',
		'OControlInterrupt',
		'ODate',
		'ODateTime',
		'ODeprecated',
		'ODictionary',
		'ODoubleByteString',
		'ODoubleByteSymbol',
		'OEndOfStream',
		'OError',
		'OException',
		'OExecBlock',
		'OExecBlock0',
		'OExecBlock1',
		'OExecBlock2',
		'OExecBlock3',
		'OExecBlock4',
		'OExecBlock5',
		'OExecBlockN',
		'OExecutableBlock',
		'OExternalError',
		'OFastIdentityKeyValueDictionary',
		'OFloat',
		'OFloatingPointError',
		'OFloatingPointException',
		'OFraction',
		'OGciTransportError',
		'OGemStoneErrorCategory',
		'OGsCurrentSession',
		'OGsFile',
		'OGsInterSessionSignal',
		'OGsMethod',
		'OGsMethodDictionary',
		'OGsNMethod',
		'OGsProcess',
		'OGsRdbConnection',
		'OGsSession',
		'OGsSocket',
		'OHalt',
		'OIdentityBag',
		'OIdentityDictionary',
		'OIdentityKeyValueDictionary',
		'OIdentitySet',
		'OIllegal',
		'OImproperOperation',
		'OIndexingErrorPreventingCommit',
		'OInteger',
		'OIntegerKeyValueDictionary',
		'OInternalError',
		'OInterSessionSignal',
		'OInterval',
		'OInvariantArray',
		'OInvariantString',
		'OIOError',
		'OISOLatin',
		'OKeyValueDictionary',
		'OLanguageDictionary',
		'OLargeInteger',
		'OLargeNegativeInteger',
		'OLargePositiveInteger',
		'OLockError',
		'OLookupError',
		'OMessageNotUnderstood',
		'OMetaclass',
		'ONameError',
		'ONotification',
		'ONumber',
		'ONumericError',
		'OObject',
		'OObjectsCommittedNotification',
		'OObsoleteGsSocket',
		'OObsoleteSymbol',
		'OOffsetError',
		'OOrderedCollection',
		'OOutOfRange',
		'OPositionableStream',
		'OQuadByteString',
		'OQuadByteSymbol',
		'ORcCounter',
		'ORcIdentityBag',
		'ORcKeyValueDictionary',
		'ORcQueue',
		'OReadStream',
		'ORegexpError',
		'ORepositoryError',
		'ORepositoryViewLost',
		'OScaledDecimal',
		'OSecurityError',
		'OSegment',
		'OSelectBlock',
		'OSequenceableCollection',
		'OSet',
		'OSignalBufferFull',
		'OSimpleBlock',
		'OSmallFloat',
		'OSmallInteger',
		'OSocketError',
		'OSortedCollection',
		'OStream',
		'OString',
		'OStringKeyValueDictionary',
		'OSymbol',
		'OSymbolAssociation',
		'OSymbolDictionary',
		'OSymbolKeyValueDictionary',
		'OSymbolList',
		'OSymbolSet',
		'OSystem',
		'OSystemCallError',
		'OTerminateProcess',
		'OTestFailure',
		'OThreadError',
		'OTime',
		'OTimeZone',
		'OTransactionBacklog',
		'OTransactionError',
		'OUnauthorizedObjectStub',
		'OUncontinuableError',
		'OUndefinedObject',
		'OUnorderedCollection',
		'OUserDefinedError',
		'OUserProfile',
		'OUserProfileSet',
		'OWarning',
		'OWriteStream',
		'OZeroDivide',
		'OObsDoubleByteString',
		'OObsDoubleByteSymbol',
		'OObsFloat',
		'OObsGsFile',
		'OObsGsProcess',
		'OObsMetaclass',
		'OObsQuadByteString',
		'OObsQuadByteSymbol',
		'OObsScaledDecimal',
		'OObsSmallFloat'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxKernelPomOop >> hash
[
	^oopNumber hash
]

{ #category : 'accessing' }
GbxKernelPomOop >> oopNumber
[
	^oopNumber
]

{ #category : 'converting to delegate' }
GbxKernelPomOop >> gbxExistingOrSpecialDelegateInSession: aSession 
[
	"Once upon a time, OIllegal could not live in the cache, because its 0 oopNumber was the same as the tombstone.
	That's no longer true, but still the session keeps the delegate for it. All other POM oops live in the cache."

	^oopNumber == 0 
		ifTrue: [aSession oopIllegal]
		ifFalse: 
			[GbxDelegate oopValue: (aSession oopForOopNumber: oopNumber)
				session: aSession]
]

{ #category : 'converting to delegate' }
GbxKernelPomOop >> asGSObjectInSession: aSession
[
	"Once upon a time, OIllegal could not live in the cache, because its 0 oopNumber was the same as the tombstone.
	That's no longer true, but still the session keeps the delegate for it. All other POM oops live in the cache."

	^self gbxExistingOrSpecialDelegateInSession: aSession
]

{ #category : 'initialize-release' }
GbxKernelPomOop >> oopNumber: anInteger 
[
	oopNumber := anInteger
]

{ #category : 'printing' }
GbxKernelPomOop >> printOn: aStream
[

	| variableName |
	variableName := self variableName.
	aStream
		nextPutAll: self class name;
		space.
	variableName == nil
		ifTrue: 
			[aStream nextPutAll: 'oopNumber: '.
			oopNumber printOn: aStream]
		ifFalse: [aStream nextPutAll: variableName]
]

{ #category : 'printing' }
GbxKernelPomOop >> variableName
[
	SpecialGemStoneObjects bindingsDo: [:b | self = b value ifTrue: [^b key]].
	^nil
]

{ #category : 'converting' }
GbxKernelPomOop >> asKernelPomOop
[
	^self
]

{ #category : 'class initialization' }
GbxKernelPomOop class >> initialize
[
	"GbxKernelPomOop initialize"

	OAbstractDictionary := GbxKernelPomOop oopNumber: 432.
	OAbstractException := GbxKernelPomOop oopNumber: 509.
	OAdmonition := GbxKernelPomOop oopNumber: 589.
	OAlmostOutOfMemory := GbxKernelPomOop oopNumber: 542.
	OAlmostOutOfStack := GbxKernelPomOop oopNumber: 554.
	OArgumentError := GbxKernelPomOop oopNumber: 543.
	OArgumentTypeError := GbxKernelPomOop oopNumber: 553.
	OArray := GbxKernelPomOop oopNumber: 261.
	OAssociation := GbxKernelPomOop oopNumber: 262.
	OBag := GbxKernelPomOop oopNumber: 401.
	OBehavior := GbxKernelPomOop oopNumber: 264.
	OBlockClosure := GbxKernelPomOop oopNumber: 330.
	OBoolean := GbxKernelPomOop oopNumber: 266.
	OBreak := GbxKernelPomOop oopNumber: 577.
	OBreakpoint := GbxKernelPomOop oopNumber: 578.
	OByteArray := GbxKernelPomOop oopNumber: 404.
	OCannotReturn := GbxKernelPomOop oopNumber: 555.
	OCharacter := GbxKernelPomOop oopNumber: 267.
	OCharacterCollection := GbxKernelPomOop oopNumber: 314.
	OClampSpecification := GbxKernelPomOop oopNumber: 530.
	OClampSpecificationOLD := GbxKernelPomOop oopNumber: 430.
	OClass := GbxKernelPomOop oopNumber: 268.
	OClassOrganizer := GbxKernelPomOop oopNumber: 364.
	OClassSet := GbxKernelPomOop oopNumber: 366.
	OClientForwarder := GbxKernelPomOop oopNumber: 428.
	OClientForwarderSend := GbxKernelPomOop oopNumber: 579.
	OCollection := GbxKernelPomOop oopNumber: 269.
	OCompileError := GbxKernelPomOop oopNumber: 516.
	OComplexBlock := GbxKernelPomOop oopNumber: 333.
	OComplexVCBlock := GbxKernelPomOop oopNumber: 334.
	OControlInterrupt := GbxKernelPomOop oopNumber: 519.
	ODate := GbxKernelPomOop oopNumber: 393.
	ODateTime := GbxKernelPomOop oopNumber: 464.
	ODeprecated := GbxKernelPomOop oopNumber: 590.
	ODictionary := GbxKernelPomOop oopNumber: 396.
	ODoubleByteString := GbxKernelPomOop oopNumber: 562.
	ODoubleByteSymbol := GbxKernelPomOop oopNumber: 563.
	OObsDoubleByteString := GbxKernelPomOop oopNumber: 388.
	OObsDoubleByteSymbol := GbxKernelPomOop oopNumber: 389.
	OEndOfStream := GbxKernelPomOop oopNumber: 580.
	OError := GbxKernelPomOop oopNumber: 511.
	OException := GbxKernelPomOop oopNumber: 538.
	OExecBlock := GbxKernelPomOop oopNumber: 560.
	OExecBlock0 := GbxKernelPomOop oopNumber: 499.
	OExecBlock1 := GbxKernelPomOop oopNumber: 500.
	OExecBlock2 := GbxKernelPomOop oopNumber: 501.
	OExecBlock3 := GbxKernelPomOop oopNumber: 502.
	OExecBlock4 := GbxKernelPomOop oopNumber: 503.
	OExecBlock5 := GbxKernelPomOop oopNumber: 504.
	OExecBlockN := GbxKernelPomOop oopNumber: 505.
	OExecutableBlock := GbxKernelPomOop oopNumber: 331.
	OExternalError := GbxKernelPomOop oopNumber: 581.
	OFastIdentityKeyValueDictionary := GbxKernelPomOop oopNumber: 468.
	OFloat := GbxKernelPomOop oopNumber: 531.
	OFloatingPointError := GbxKernelPomOop oopNumber: 548.
	OFloatingPointException := GbxKernelPomOop oopNumber: 591.
	OObsFloat := GbxKernelPomOop oopNumber: 380.
	OFraction := GbxKernelPomOop oopNumber: 304.
	OGciTransportError := GbxKernelPomOop oopNumber: 583.
	OGemStoneErrorCategory := GbxKernelPomOop oopNumber: 903.
	OGsCurrentSession := GbxKernelPomOop oopNumber: 406.
	OObsGsFile := GbxKernelPomOop oopNumber: 449.
	OGsFile := GbxKernelPomOop oopNumber: 528.
	OGsInterSessionSignal := GbxKernelPomOop oopNumber: 410.
	OGsMethod := GbxKernelPomOop oopNumber: 386.
	OGsMethodDictionary := GbxKernelPomOop oopNumber: 387.
	OGsNMethod := GbxKernelPomOop oopNumber: 566.
	OObsGsProcess := GbxKernelPomOop oopNumber: 390.
	OGsProcess := GbxKernelPomOop oopNumber: 526.
	OGsRdbConnection := GbxKernelPomOop oopNumber: 409.
	OGsSession := GbxKernelPomOop oopNumber: 405.
	OGsSocket := GbxKernelPomOop oopNumber: 529.
	OHalt := GbxKernelPomOop oopNumber: 520.
	OIdentityBag := GbxKernelPomOop oopNumber: 263.
	OIdentityDictionary := GbxKernelPomOop oopNumber: 397.
	OIdentityKeyValueDictionary := GbxKernelPomOop oopNumber: 355.
	OIdentitySet := GbxKernelPomOop oopNumber: 289.
	OIllegal := GbxKernelPomOop oopNumber: 0.
	OImproperOperation := GbxKernelPomOop oopNumber: 557.
	OIndexingErrorPreventingCommit := GbxKernelPomOop oopNumber: 582.
	OInteger := GbxKernelPomOop oopNumber: 274.
	OIntegerKeyValueDictionary := GbxKernelPomOop oopNumber: 311.
	OInternalError := GbxKernelPomOop oopNumber: 515.
	OInterSessionSignal := GbxKernelPomOop oopNumber: 598.
	OInterval := GbxKernelPomOop oopNumber: 403.
	OInvariantArray := GbxKernelPomOop oopNumber: 275.
	OInvariantString := GbxKernelPomOop oopNumber: 276.
	OIOError := GbxKernelPomOop oopNumber: 544.
	OISOLatin := GbxKernelPomOop oopNumber: 378.
	OKeyValueDictionary := GbxKernelPomOop oopNumber: 310.
	OLanguageDictionary := GbxKernelPomOop oopNumber: 398.
	OLargeInteger := GbxKernelPomOop oopNumber: 532.
	OLargeNegativeInteger := GbxKernelPomOop oopNumber: 303.
	OLargePositiveInteger := GbxKernelPomOop oopNumber: 302.
	OLockError := GbxKernelPomOop oopNumber: 584.
	OLookupError := GbxKernelPomOop oopNumber: 517.
	OObsMetaclass := GbxKernelPomOop oopNumber: 279.
	OMessageNotUnderstood := GbxKernelPomOop oopNumber: 512.
	OMetaclass := GbxKernelPomOop oopNumber: 571.
	ONameError := GbxKernelPomOop oopNumber: 514.
	ONotification := GbxKernelPomOop oopNumber: 521.
	ONumber := GbxKernelPomOop oopNumber: 281.
	ONumericError := GbxKernelPomOop oopNumber: 585.
	OObject := GbxKernelPomOop oopNumber: 282.
	OObjectsCommittedNotification := GbxKernelPomOop oopNumber: 592.
	OObsoleteGsSocket := GbxKernelPomOop oopNumber: 441.
	OObsoleteSymbol := GbxKernelPomOop oopNumber: 293.
	OOffsetError := GbxKernelPomOop oopNumber: 546.
	OOrderedCollection := GbxKernelPomOop oopNumber: 362.
	OOutOfRange := GbxKernelPomOop oopNumber: 547.
	OPositionableStream := GbxKernelPomOop oopNumber: 283.
	OQuadByteString := GbxKernelPomOop oopNumber: 564.
	OObsQuadByteString := GbxKernelPomOop oopNumber: 495.
	OQuadByteSymbol := GbxKernelPomOop oopNumber: 565.
	OObsQuadByteSymbol := GbxKernelPomOop oopNumber: 496.
	ORcCounter := GbxKernelPomOop oopNumber: 427.
	ORcIdentityBag := GbxKernelPomOop oopNumber: 412.
	ORcKeyValueDictionary := GbxKernelPomOop oopNumber: 341.
	ORcQueue := GbxKernelPomOop oopNumber: 324.
	OReadStream := GbxKernelPomOop oopNumber: 284.
	ORegexpError := GbxKernelPomOop oopNumber: 549.
	ORepositoryError := GbxKernelPomOop oopNumber: 586.
	ORepositoryViewLost := GbxKernelPomOop oopNumber: 545.
	OObsScaledDecimal := GbxKernelPomOop oopNumber: 402.
	OScaledDecimal := GbxKernelPomOop oopNumber: 572.
	OSecurityError := GbxKernelPomOop oopNumber: 550.
	OSegment := GbxKernelPomOop oopNumber: 286.
	OSelectBlock := GbxKernelPomOop oopNumber: 335.
	OSequenceableCollection := GbxKernelPomOop oopNumber: 288.
	OSet := GbxKernelPomOop oopNumber: 400.
	OSignalBufferFull := GbxKernelPomOop oopNumber: 597.
	OSimpleBlock := GbxKernelPomOop oopNumber: 332.
	OSmallFloat := GbxKernelPomOop oopNumber: 534.
	OObsSmallFloat := GbxKernelPomOop oopNumber: 381.
	OSmallInteger := GbxKernelPomOop oopNumber: 290.
	OSocketError := GbxKernelPomOop oopNumber: 556.
	OSortedCollection := GbxKernelPomOop oopNumber: 363.
	OStream := GbxKernelPomOop oopNumber: 291.
	OString := GbxKernelPomOop oopNumber: 292.
	OStringKeyValueDictionary := GbxKernelPomOop oopNumber: 312.
	OSymbol := GbxKernelPomOop oopNumber: 433.
	OSymbolAssociation := GbxKernelPomOop oopNumber: 436.
	OSymbolDictionary := GbxKernelPomOop oopNumber: 435.
	OSymbolKeyValueDictionary := GbxKernelPomOop oopNumber: 434.
	OSymbolList := GbxKernelPomOop oopNumber: 307.
	OSymbolSet := GbxKernelPomOop oopNumber: 445.
	OSystem := GbxKernelPomOop oopNumber: 297.
	OSystemCallError := GbxKernelPomOop oopNumber: 551.
	OTerminateProcess := GbxKernelPomOop oopNumber: 596.
	OTestFailure := GbxKernelPomOop oopNumber: 593.
	OThreadError := GbxKernelPomOop oopNumber: 552.
	OTime := GbxKernelPomOop oopNumber: 394.
	OTimeZone := GbxKernelPomOop oopNumber: 463.
	OTransactionBacklog := GbxKernelPomOop oopNumber: 594.
	OTransactionError := GbxKernelPomOop oopNumber: 587.
	OUnauthorizedObjectStub := GbxKernelPomOop oopNumber: 609.
	OUncontinuableError := GbxKernelPomOop oopNumber: 588.
	OUndefinedObject := GbxKernelPomOop oopNumber: 298.
	OUnorderedCollection := GbxKernelPomOop oopNumber: 376.
	OUserDefinedError := GbxKernelPomOop oopNumber: 518.
	OUserProfile := GbxKernelPomOop oopNumber: 299.
	OUserProfileSet := GbxKernelPomOop oopNumber: 438.
	OWarning := GbxKernelPomOop oopNumber: 595.
	OWriteStream := GbxKernelPomOop oopNumber: 301.
	OZeroDivide := GbxKernelPomOop oopNumber: 513.
	LastKernelOopNumber := 1318	"Computed from OOP_LAST_RESERVED_OOP in oop.ht"
]

{ #category : 'instance creation' }
GbxKernelPomOop class >> oopNumber: anInteger 
[
	^self new oopNumber: anInteger
]

