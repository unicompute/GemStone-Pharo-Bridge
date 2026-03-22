Class {
	#name : 'GbxBehaviorMapTableSegmentTool',
	#superclass : 'Object',
	#instVars : [
		'segmentIndex',
		'bucketCount',
		'entries',
		'occupancy'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxBehaviorMapTableSegmentTool class >> index: anIndex bucketCount: count [
	^ self new
		segmentIndex: anIndex;
		bucketCount: count;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> at: anOop [
	"Get entry at OOP hash"
	| index |
	
	index := self hashIndexFor: anOop.
	^ entries at: index ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> at: anOop put: anEntry [
	"Put entry at OOP hash"
	| index |
	
	index := self hashIndexFor: anOop.
	(entries at: index ifAbsent: [ nil ]) ifNil: [
		occupancy := occupancy + 1.
	].
	entries at: anOop put: anEntry.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> bucketCount [
	^ bucketCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> bucketCount: anInteger [
	bucketCount := anInteger.
	entries := Dictionary new.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> clear [
	"Clear the segment"
	entries := Dictionary new.
	occupancy := 0.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> entries [
	^ entries ifNil: [ entries := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> hashIndexFor: anOop [
	"Calculate hash index for an OOP"
	^ anOop \\ bucketCount
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> occupancy [
	^ occupancy ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> percentFull [
	bucketCount = 0 ifTrue: [ ^ 0 ].
	^ (occupancy * 100) // bucketCount
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> printString [
	^ 'BehaviorMapSegment ', self segmentIndex asString,
	  ' (', self percentFull asString, '% full)'
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> segmentIndex [
	^ segmentIndex
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegmentTool >> segmentIndex: anInteger [
	segmentIndex := anInteger
]
