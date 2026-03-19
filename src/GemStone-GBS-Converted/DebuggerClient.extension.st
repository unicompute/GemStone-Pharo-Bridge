Extension { #name : #'DebuggerClient' }

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerClient class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerClient class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DebuggerClient class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerClient >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
DebuggerClient >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
DebuggerClient >> isRunningUnderAssertingVM [
	^false
]

