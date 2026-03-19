Extension { #name : #'ContextListPolicy' }

{ #category : '*GemStone-GBS-Converted-accessing' }
ContextListPolicy class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ContextListPolicy class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ContextListPolicy class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ContextListPolicy >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ContextListPolicy >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ContextListPolicy >> isRunningUnderAssertingVM [
	^false
]

