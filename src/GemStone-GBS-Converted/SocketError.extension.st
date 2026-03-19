Extension { #name : #'SocketError' }

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketError class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketError class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SocketError class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketError >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SocketError >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SocketError >> isRunningUnderAssertingVM [
	^false
]

