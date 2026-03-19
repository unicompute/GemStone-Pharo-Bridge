Extension { #name : #'TextAttribute' }

{ #category : '*GemStone-GBS-Converted-accessing' }
TextAttribute class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextAttribute class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TextAttribute class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextAttribute >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextAttribute >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TextAttribute >> isRunningUnderAssertingVM [
	^false
]

