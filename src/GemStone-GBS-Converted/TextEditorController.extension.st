Extension { #name : #'TextEditorController' }

{ #category : '*GemStone-GBS-Converted-accessing' }
TextEditorController class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextEditorController class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TextEditorController class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextEditorController >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
TextEditorController >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
TextEditorController >> isRunningUnderAssertingVM [
	^false
]

