Extension { #name : #'DocumentInspector' }

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentInspector class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentInspector class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DocumentInspector class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentInspector >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DocumentInspector >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DocumentInspector >> isRunningUnderAssertingVM [
	^false
]

