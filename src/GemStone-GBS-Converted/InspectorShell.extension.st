Extension { #name : #'InspectorShell' }

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorShell class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorShell class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
InspectorShell class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorShell >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
InspectorShell >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
InspectorShell >> isRunningUnderAssertingVM [
	^false
]

