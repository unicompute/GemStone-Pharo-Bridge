Extension { #name : #'Model' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Model class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Model class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Model class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Model >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Model >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Model >> isRunningUnderAssertingVM [
	^false
]

