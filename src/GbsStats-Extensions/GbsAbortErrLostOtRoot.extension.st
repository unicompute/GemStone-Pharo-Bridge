Extension { #name : 'GbsAbortErrLostOtRoot' }

{ #category : '*GbsStats-Extensions' }
GbsAbortErrLostOtRoot class >> updateStats: aStatResource
[
	"Reimplement this method in specific exception classes to update 
	 stats if necessory.  This is only invoked if stats are enabled."

	aStatResource incLostOtRoots
]

