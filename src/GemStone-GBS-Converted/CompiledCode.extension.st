Extension { #name : #'CompiledCode' }

{ #category : '*GemStone-GBS-Converted-private-GBS-extensions' }
CompiledCode >> gbxDeepCopyCycles: cycles [
	"GBS private"

	^self
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

