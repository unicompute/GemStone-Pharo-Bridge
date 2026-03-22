Class {
	#name : 'GbxServerMapTableSegmentTool',
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
GbxServerMapTableSegmentTool class >> segmentId: anId name: aString [
	^ self new
		segmentId: anId;
		segmentName: aString;
		yourself
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> addNode: aNode [
	"Add a node to this segment"
	nodes ifNil: [ nodes := OrderedCollection new ].
	nodes add: aNode.
	occupancy := occupancy + 1.
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> bucketCount [
	^ bucketCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> bucketCount: anInteger [
	bucketCount := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> nodes [
	^ nodes ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> nodes: aCollection [
	nodes := aCollection.
	occupancy := aCollection size.
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> occupancy [
	^ occupancy ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> occupancy: anInteger [
	occupancy := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> percentFull [
	bucketCount = 0 ifTrue: [ ^ 0 ].
	^ (occupancy * 100) // bucketCount
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> printString [
	^ 'Segment ', segmentName, ' (id: ', segmentId asString, ', ',
	  self percentFull asString, '% full)'
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> segmentId [
	^ segmentId
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> segmentId: anInteger [
	segmentId := anInteger
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> segmentName [
	^ segmentName
]

{ #category : 'accessing' }
GbxServerMapTableSegmentTool >> segmentName: aString [
	segmentName := aString
]
