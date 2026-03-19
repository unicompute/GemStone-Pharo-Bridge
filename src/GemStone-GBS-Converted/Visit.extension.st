Extension { #name : #'Visit' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Visit class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Visit class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Visit class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Visit >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Visit >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Visit >> isRunningUnderAssertingVM [
	^false
]

