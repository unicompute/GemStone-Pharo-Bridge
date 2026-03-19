Extension { #name : #'CompiledBlock' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
CompiledBlock >> gbxHasSource [

	^ self hasSourceCode
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledBlock class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledBlock class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledBlock class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledBlock >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CompiledBlock >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CompiledBlock >> isRunningUnderAssertingVM [
	^false
]
