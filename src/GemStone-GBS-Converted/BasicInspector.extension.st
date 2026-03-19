Extension { #name : #'BasicInspector' }

{ #category : '*GemStone-GBS-Converted-accessing' }
BasicInspector class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
BasicInspector class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
BasicInspector class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
BasicInspector >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
BasicInspector >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
BasicInspector >> isRunningUnderAssertingVM [
	^false
]

