Extension { #name : #'LargeInteger' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
LargeInteger class >> gbsByteSwizzleStride [

	^2	"4-byte swizzling"
]

{ #category : '*GemStone-GBS-Converted-GBS-private' }
LargeInteger class >> gbsReplicatorClass [

	^GbxLargeIntegerReplicator
]

{ #category : '*GemStone-GBS-Converted-accessing' }
LargeInteger class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
LargeInteger class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
LargeInteger class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
LargeInteger >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
LargeInteger >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
LargeInteger >> isRunningUnderAssertingVM [
	^false
]

