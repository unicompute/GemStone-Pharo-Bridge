Extension { #name : #'DebuggerService' }

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerService class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerService class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DebuggerService class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerService >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerService >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DebuggerService >> isRunningUnderAssertingVM [
	^false
]

