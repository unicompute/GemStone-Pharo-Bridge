Extension { #name : #'DocumentView' }

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentView class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentView class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DocumentView class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentView >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentView >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DocumentView >> isRunningUnderAssertingVM [
	^false
]

