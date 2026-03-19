Extension { #name : #'Menu' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Menu class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Menu class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Menu class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Menu >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Menu >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Menu >> isRunningUnderAssertingVM [
	^false
]

