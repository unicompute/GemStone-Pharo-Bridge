Extension { #name : #'ModularSettingsPage' }

{ #category : '*GemStone-GBS-Converted-accessing' }
ModularSettingsPage class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModularSettingsPage class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ModularSettingsPage class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModularSettingsPage >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ModularSettingsPage >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ModularSettingsPage >> isRunningUnderAssertingVM [
	^false
]

