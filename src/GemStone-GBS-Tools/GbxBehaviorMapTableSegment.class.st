Class {
	#name : 'GbxBehaviorMapTableSegment',
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
GbxBehaviorMapTableSegment class >> index: anIndex bucketCount: count [
	^ self new
		segmentIndex: anIndex;
		bucketCount: count;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> at: anOop [
	"Get entry at OOP hash"
	| index |
	
	index := self hashIndexFor: anOop.
	^ entries at: index ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> at: anOop put: anEntry [
	"Put entry at OOP hash"
	| index |
	
	index := self hashIndexFor: anOop.
	(entries at: index ifAbsent: [ nil ]) ifNil: [
		occupancy := occupancy + 1.
	].
	entries at: anOop put: anEntry.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> bucketCount [
	^ bucketCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> bucketCount: anInteger [
	bucketCount := anInteger.
	entries := Dictionary new.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> clear [
	"Clear the segment"
	entries := Dictionary new.
	occupancy := 0.
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> entries [
	^ entries ifNil: [ entries := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> hashIndexFor: anOop [
	"Calculate hash index for an OOP"
	^ anOop \\ bucketCount
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> occupancy [
	^ occupancy ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> percentFull [
	bucketCount = 0 ifTrue: [ ^ 0 ].
	^ (occupancy * 100) // bucketCount
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> printString [
	^ 'BehaviorMapSegment ', segmentIndex asString,
	  ' (', percentFull asString, '% full)'
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> segmentIndex [
	^ segmentIndex
]

{ #category : 'accessing' }
GbxBehaviorMapTableSegment >> segmentIndex: anInteger [
	segmentIndex := anInteger
]
