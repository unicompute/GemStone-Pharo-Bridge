Extension { #name : #'CannotReturn' }

{ #category : '*GemStone-GBS-Converted-accessing' }
CannotReturn class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CannotReturn class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CannotReturn class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CannotReturn >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
CannotReturn >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
CannotReturn >> isRunningUnderAssertingVM [
	^false
]

