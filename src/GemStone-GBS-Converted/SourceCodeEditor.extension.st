Extension { #name : #'SourceCodeEditor' }

{ #category : '*GemStone-GBS-Converted-accessing' }
SourceCodeEditor class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SourceCodeEditor class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SourceCodeEditor class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SourceCodeEditor >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SourceCodeEditor >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SourceCodeEditor >> isRunningUnderAssertingVM [
	^false
]

