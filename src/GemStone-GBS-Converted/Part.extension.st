Extension { #name : #'Part' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Part class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Part class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Part class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Part >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Part >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Part >> isRunningUnderAssertingVM [
	^false
]

