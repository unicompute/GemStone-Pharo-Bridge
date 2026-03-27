Extension { #name : 'GbsRtErrSignalAbort' }

{ #category : '*GbsStats-Extensions' }
GbsRtErrSignalAbort class >> updateStats: aStatResource
[
	"Reimplement this method in specific exception classes to update 
	 stats if necessory.  This is only invoked if stats are enabled."

	aStatResource incSigAborts
]

