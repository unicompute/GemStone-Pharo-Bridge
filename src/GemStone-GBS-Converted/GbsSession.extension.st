Extension { #name : 'GbsSession' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
GbsSession >> isLoggedIn: aBoolean [
	aBoolean ifFalse: [ sessionId := 0 ].
	^ aBoolean
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
GbsSession >> parameters: aGbsSessionParameters [
	parameters := aGbsSessionParameters
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
GbsSession >> sessionId: anInteger [
	sessionId := anInteger
]
