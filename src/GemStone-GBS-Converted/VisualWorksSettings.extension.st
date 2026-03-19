Extension { #name : #'VisualWorksSettings' }

{ #category : '*GemStone-GBS-Converted-accessing' }
VisualWorksSettings class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
VisualWorksSettings class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
VisualWorksSettings class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
VisualWorksSettings >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
VisualWorksSettings >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
VisualWorksSettings >> isRunningUnderAssertingVM [
	^false
]

