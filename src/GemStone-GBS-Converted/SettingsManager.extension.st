Extension { #name : #'SettingsManager' }

{ #category : '*GemStone-GBS-Converted-accessing' }
SettingsManager class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SettingsManager class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SettingsManager class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SettingsManager >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SettingsManager >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SettingsManager >> isRunningUnderAssertingVM [
	^false
]

