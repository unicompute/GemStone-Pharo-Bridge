Extension { #name : 'GciError' }

{ #category : '*GemStone-GBS-Core' }
GciError >> number [
	"Manually read the first int32 field after the four uint64 slots."
	^ handle signedLongAt: 33
]
