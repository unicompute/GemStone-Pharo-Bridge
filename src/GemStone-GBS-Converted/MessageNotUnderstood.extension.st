Extension { #name : #'MessageNotUnderstood' }

{ #category : '*GemStone-GBS-Converted-accessing' }
MessageNotUnderstood class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
MessageNotUnderstood class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
MessageNotUnderstood class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
MessageNotUnderstood >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
MessageNotUnderstood >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
MessageNotUnderstood >> isRunningUnderAssertingVM [
	^false
]

