Extension { #name : #'CompiledMethod' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
CompiledMethod >> gbxHasSource [

	^self sourcePointer notNil
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
CompiledMethod >> gbxSelector [

	^self selector
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledMethod class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledMethod class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledMethod class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledMethod >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledMethod >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledMethod >> isRunningUnderAssertingVM [
	^false
]

