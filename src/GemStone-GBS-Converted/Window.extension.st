Extension { #name : #'Window' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Window class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Window class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Window class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Window >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Window >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Window >> isRunningUnderAssertingVM [
	^false
]

