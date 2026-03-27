Extension { #name : 'GbsRtErrSignalGemStoneSession' }

{ #category : '*GbsStats-Extensions' }
GbsRtErrSignalGemStoneSession class >> updateStats: aStatResource
[
	"Reimplement this method in specific exception classes to update 
	 stats if necessory.  This is only invoked if stats are enabled."

	aStatResource incSessionSignals
]

