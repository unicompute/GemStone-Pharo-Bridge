Extension { #name : #'AbstractChangeList' }

{ #category : '*GemStone-GBS-Converted-accessing' }
AbstractChangeList class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
AbstractChangeList class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
AbstractChangeList class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
AbstractChangeList >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
AbstractChangeList >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
AbstractChangeList >> isRunningUnderAssertingVM [
	^false
]

