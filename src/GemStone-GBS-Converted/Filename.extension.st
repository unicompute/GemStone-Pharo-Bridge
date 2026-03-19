Extension { #name : #'Filename' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Filename class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Filename class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Filename class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Filename >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Filename >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Filename >> isRunningUnderAssertingVM [
	^false
]

