Extension { #name : #'Workspace' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Workspace class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workspace class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Workspace class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workspace >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workspace >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Workspace >> isRunningUnderAssertingVM [
	^false
]

