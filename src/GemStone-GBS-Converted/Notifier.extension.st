Extension { #name : #'Notifier' }

{ #category : '*GemStone-GBS-Converted-accessing' }
Notifier class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Notifier class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Notifier class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Notifier >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Notifier >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Notifier >> isRunningUnderAssertingVM [
	^false
]

