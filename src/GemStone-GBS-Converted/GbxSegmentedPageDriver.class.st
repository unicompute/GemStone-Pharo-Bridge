Class {
	#name : 'GbxSegmentedPageDriver',
	#superclass : 'Object',
	#instVars : [
		'page',
		'segmentSize'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxSegmentedPageDriver >> computeFieldList [
	(page respondsTo: #computeFieldList)
		ifTrue: [ ^ page computeFieldList ].
	(page respondsTo: #fieldList)
		ifTrue: [ ^ page fieldList ].
	^ #()
]

{ #category : 'private' }
GbxSegmentedPageDriver >> computeSegmentList [
	| segments totalSize |
	segments := OrderedCollection new.
	totalSize := page partCount.
	1 to: totalSize by: self segmentSize do: [ :base |
		| end segment |
		end := (base + self segmentSize - 1) min: totalSize.
		segment := GbxObjectSegment new.
		segment
			from: base
			part: (page gbxDriverPartAt: base)
			to: end
			part: (page gbxDriverPartAt: end);
			isUncached: true.
		self markSegmentCached: segment ifBetween: base and: end.
		segments add: segment ].
	^ segments asArray
]

{ #category : 'private' }
GbxSegmentedPageDriver >> markSegmentCached: aSegment ifBetween: base and: end [
	(page respondsTo: #gbxCachedRanges) ifFalse: [ ^ self ].
	page gbxCachedRanges do: [ :interval |
		(interval first <= base and: [ interval last >= end ])
			ifTrue: [ aSegment isUncached: false ] ]
]

{ #category : 'accessing' }
GbxSegmentedPageDriver >> page: anObject [
	page := anObject
]

{ #category : 'notifications' }
GbxSegmentedPageDriver >> segmentSelectionChanged [
	| segments |
	(page respondsTo: #selectedSegments)
		ifFalse: [ ^ self ].
	segments := page selectedSegments asSortedCollection.
	segments do: [ :segment |
		segment isUncached ifTrue: [
			GBSM showBusyWhile: [
				page gbxCacheInterval: (segment firstIndex to: segment lastIndex) ].
			segment
				firstPart: (page gbxDriverPartAt: segment firstIndex);
				lastPart: (page gbxDriverPartAt: segment lastIndex);
				cached ] ].
	(page respondsTo: #fieldList:)
		ifTrue: [ page fieldList: self computeFieldList ]
]

{ #category : 'accessing' }
GbxSegmentedPageDriver >> segmentSize [
	^ segmentSize ifNil: [ 25 ]
]

{ #category : 'accessing' }
GbxSegmentedPageDriver >> segmentSize: anInteger [
	segmentSize := anInteger
]
