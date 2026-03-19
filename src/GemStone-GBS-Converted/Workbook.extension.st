Extension { #name : #'Workbook' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Workbook class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workbook class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Workbook class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workbook >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Workbook >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Workbook >> isRunningUnderAssertingVM [
	^false
]

