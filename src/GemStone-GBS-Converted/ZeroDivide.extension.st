Extension { #name : #'ZeroDivide' }

{ #category : '*GemStone-GBS-Converted-accessing' }
ZeroDivide class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ZeroDivide class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ZeroDivide class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ZeroDivide >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
ZeroDivide >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
ZeroDivide >> isRunningUnderAssertingVM [
	^false
]

