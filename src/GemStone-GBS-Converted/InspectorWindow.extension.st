Extension { #name : #'InspectorWindow' }

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorWindow class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorWindow class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
InspectorWindow class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorWindow >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorWindow >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
InspectorWindow >> isRunningUnderAssertingVM [
	^false
]

