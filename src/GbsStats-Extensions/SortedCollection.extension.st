Extension { #name : 'SortedCollection' }

{ #category : '*GbsStats-Extensions' }
SortedCollection >> gbxBytesCached
[
	"Although a SortedCollection contains a sortBlock, this method doesn't need
	 to include it in the bytes tally, because the sortBlock will be referenced by
	 the GBS cache directly, and so will be counted."

	^super gbxBytesCached
]

