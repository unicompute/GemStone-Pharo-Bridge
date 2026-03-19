Extension { #name : #'PartListAbstractInspector' }

{ #category : '*GemStone-GBS-Converted-accessing' }
PartListAbstractInspector class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartListAbstractInspector class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PartListAbstractInspector class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartListAbstractInspector >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartListAbstractInspector >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PartListAbstractInspector >> isRunningUnderAssertingVM [
	^false
]

