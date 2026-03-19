Extension { #name : #'UIManager' }

{ #category : '*GemStone-GBS-Converted' }
UIManager >> includesKey: aSymbol [
	"Simulate VisualWorks UI namespace behavior for Smalltalk at: #UI"
	^true
]

{ #category : '*GemStone-GBS-Converted' }
UIManager >> at: aSymbol [
	"Simulate VisualWorks UI namespace behavior for Smalltalk at: #UI"
	^self
]

{ #category : '*GemStone-GBS-Converted-accessing' }
UIManager class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
UIManager class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
UIManager class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
UIManager >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
UIManager >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
UIManager >> isRunningUnderAssertingVM [
	^false
]

