Extension { #name : #'ParagraphEditor' }

{ #category : '*GemStone-GBS-Converted-accessing' }
ParagraphEditor class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ParagraphEditor class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ParagraphEditor class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ParagraphEditor >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ParagraphEditor >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ParagraphEditor >> isRunningUnderAssertingVM [
	^false
]

