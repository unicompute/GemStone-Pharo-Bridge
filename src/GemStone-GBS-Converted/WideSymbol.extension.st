Extension { #name : #'WideSymbol' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
WideSymbol class >> gbsByteSwizzleStride [
	"In theory, we never send Symbols to the server in a traversal buffer, so this method should not be needed."

	^1	"2-byte swizzling"
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideSymbol >> gbxAsServerBytes [
	"Private.  GBS.  GemStone support.  Preparation for copying to heap."

	^self asTwoByteString gbxAsServerBytes
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideSymbol class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideSymbol class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WideSymbol class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideSymbol >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideSymbol >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WideSymbol >> isRunningUnderAssertingVM [
	^false
]

