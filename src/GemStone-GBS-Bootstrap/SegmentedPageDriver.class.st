Class {
	#name : 'SegmentedPageDriver',
	#superclass : 'Object',
	#instVars : [
		'page',
		'segmentSize'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
SegmentedPageDriver >> computeSegmentList
[
	"VisualWorks compatibility stub"
	^#()
]

{ #category : 'accessing' }
SegmentedPageDriver >> markSegmentCached: anObject ifBetween: start and: end
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
SegmentedPageDriver >> segmentSelectionChanged
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
SegmentedPageDriver >> computeFieldList
[
	^#()
]

{ #category : 'accessing' }
SegmentedPageDriver >> page
[
	^page
]

{ #category : 'accessing' }
SegmentedPageDriver >> page: anObject
[
	page := anObject
]

{ #category : 'accessing' }
SegmentedPageDriver >> segmentSize
[
	^segmentSize ifNil: [ 25 ]
]

{ #category : 'accessing' }
SegmentedPageDriver >> segmentSize: anInteger
[
	segmentSize := anInteger
]
