Extension { #name : 'GciError' }

{ #category : '*GemStone-Pharo-Tests' }
GciError >> number [
	^ handle signedLongAt: 33
]

{ #category : '*GemStone-Pharo-Tests' }
GciError >> number: anInteger [
	handle signedLongAt: 33 put: anInteger
]
