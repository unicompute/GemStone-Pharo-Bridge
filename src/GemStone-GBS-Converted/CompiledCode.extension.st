Extension { #name : #'CompiledCode' }

{ #category : '*GemStone-GBS-Converted-private-GBS-extensions' }
CompiledCode >> gbxDeepCopyCycles: cycles [
	"GBS private"

	^self
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
CompiledCode >> at: index [
	"VW compatibility: Return the literal at the given index."

	^ self literalAt: index
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
CompiledCode >> homeMethod [
	"VW compatibility: Answer the home method of the receiver."

	^ self method
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledCode class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledCode class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledCode class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledCode >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledCode >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledCode >> isRunningUnderAssertingVM [
	^false
]

