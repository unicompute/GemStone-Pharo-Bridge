Class {
	#name : 'GbxSegmentedPageDriver',
	#superclass : 'SegmentedPageDriver',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'private' }
GbxSegmentedPageDriver >> markSegmentCached: segment ifBetween: base and: end 
	"for now, safely(?) assume that any cached range would never be anything but a superset of the range passed in"

	page gbxCachedRanges do: 
			[:interval | 
			(interval first <= base and: [interval last >= end]) 
				ifTrue: [segment isUncached: false]]

{ #category : 'private' }
GbxSegmentedPageDriver >> computeSegmentList
	"Answer a sequence consisting of everything to show in the segement list. The first segment's part's are just dummy Part's which is slightly different than trippy's behavior. GemStone collections will only show the 'index' range, not the key or index printStrings. "

	| segments totalSize |
	segments := OrderedCollection new.
	totalSize := page partCount.
	1 to: totalSize
		by: segmentSize
		do: 
			[:base | 
			| end segment |
			end := base + segmentSize - 1 min: totalSize.
			segment := GbxObjectSegment new 
						from: base
						part: (page gbxDriverPartAt: base)
						to: end
						part: (page gbxDriverPartAt: end).
			segment isUncached: true.
			self 
				markSegmentCached: segment
				ifBetween: base
				and: end.
			segments add: segment].
	^segments

{ #category : 'notifications' }
GbxSegmentedPageDriver >> segmentSelectionChanged
	| segments |
	segments := page segmentListHolder selections asSortedCollection.
	segments do: 
			[:segment | 
			segment isUncached 
				ifTrue: 
					[GBSM showBusyWhile: 
							[page gbxCacheInterval: (segment firstIndex to: segment lastIndex)].
					segment firstPart: (page gbxDriverPartAt: segment firstIndex).
					segment lastPart: (page gbxDriverPartAt: segment lastIndex).
					segment cached]].
	page fieldListHolder list: self computeFieldList

