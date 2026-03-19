Extension { #name : #'WriteStream' }

{ #category : '*GemStone-GBS-Converted-accessing' }
WriteStream class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WriteStream class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WriteStream class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WriteStream >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WriteStream >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WriteStream >> isRunningUnderAssertingVM [
	^false
]

