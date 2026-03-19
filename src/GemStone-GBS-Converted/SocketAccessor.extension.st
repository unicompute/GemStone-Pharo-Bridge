Extension { #name : #'SocketAccessor' }

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketAccessor class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketAccessor class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SocketAccessor class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketAccessor >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketAccessor >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SocketAccessor >> isRunningUnderAssertingVM [
	^false
]

