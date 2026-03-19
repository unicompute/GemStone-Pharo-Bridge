Extension { #name : #'FileBrowser' }

{ #category : '*GemStone-GBS-Converted-accessing' }
FileBrowser class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
FileBrowser class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
FileBrowser class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
FileBrowser >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
FileBrowser >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
FileBrowser >> isRunningUnderAssertingVM [
	^false
]

