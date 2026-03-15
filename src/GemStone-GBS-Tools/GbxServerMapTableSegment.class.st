Class {
	#name : 'GbxServerMapTableSegment',
	#superclass : 'Object',
	#instVars : [
		'segmentId',
		'segmentName',
		'bucketCount',
		'occupancy',
		'nodes',
		'needFinalization'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxServerMapTableSegment class >> segmentId: anId name: aString [
	^ self new
		segmentId: anId;
		segmentName: aString;
		yourself
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> addNode: aNode [
	"Add a node to this segment"
	nodes ifNil: [ nodes := OrderedCollection new ].
	nodes add: aNode.
	occupancy := occupancy + 1.
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> bucketCount [
	^ bucketCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> bucketCount: anInteger [
	bucketCount := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> nodes [
	^ nodes ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> nodes: aCollection [
	nodes := aCollection.
	occupancy := aCollection size.
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> occupancy [
	^ occupancy ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> occupancy: anInteger [
	occupancy := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> percentFull [
	bucketCount = 0 ifTrue: [ ^ 0 ].
	^ (occupancy * 100) // bucketCount
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> printString [
	^ 'Segment ', segmentName, ' (id: ', segmentId asString, ', ',
	  self percentFull asString, '% full)'
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> segmentId [
	^ segmentId
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> segmentId: anInteger [
	segmentId := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> segmentName [
	^ segmentName
]

{ #category : 'accessing' }
GbxServerMapTableSegment >> segmentName: aString [
	segmentName := aString
]
