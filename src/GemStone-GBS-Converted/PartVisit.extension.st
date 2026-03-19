Extension { #name : #'PartVisit' }

{ #category : '*GemStone-GBS-Converted-accessing' }
PartVisit class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartVisit class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PartVisit class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartVisit >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PartVisit >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PartVisit >> isRunningUnderAssertingVM [
	^false
]

