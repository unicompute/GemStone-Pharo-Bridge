Class {
	#name : 'GbxFakeTraversalBuffer',
	#superclass : 'Object',
	#instVars : [
		'emptyCount',
		'unlockCount'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'packing' }
GbxFakeTraversalBuffer >> emptyBuffer [
	emptyCount := self emptyCount + 1
]

{ #category : 'accessing' }
GbxFakeTraversalBuffer >> emptyCount [
	^ emptyCount ifNil: [ 0 ]
]

{ #category : 'packing' }
GbxFakeTraversalBuffer >> finishedReport [
	^ true
]

{ #category : 'packing' }
GbxFakeTraversalBuffer >> hasRoomForReport [
	^ true
]

{ #category : 'packing' }
GbxFakeTraversalBuffer >> objectReport [
	^ #objectReport
]

{ #category : 'locking' }
GbxFakeTraversalBuffer >> unlockFor: aTraversal [
	unlockCount := self unlockCount + 1
]

{ #category : 'accessing' }
GbxFakeTraversalBuffer >> unlockCount [
	^ unlockCount ifNil: [ 0 ]
]
