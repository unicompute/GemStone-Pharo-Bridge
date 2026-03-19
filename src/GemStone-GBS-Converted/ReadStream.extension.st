Extension { #name : #'ReadStream' }

{ #category : '*GemStone-GBS-Converted-accessing' }
ReadStream class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ReadStream class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ReadStream class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ReadStream >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ReadStream >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ReadStream >> isRunningUnderAssertingVM [
	^false
]

