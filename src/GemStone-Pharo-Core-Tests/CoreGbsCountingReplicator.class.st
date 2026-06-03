Class {
	#name : 'CoreGbsCountingReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
		'serverOffsetRefreshCount'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreGbsCountingReplicator >> initialize [
	super initialize.
	serverOffsetRefreshCount := 0
]

{ #category : 'initialization' }
CoreGbsCountingReplicator >> initializeServerOffsets [
	serverOffsetRefreshCount := self serverOffsetRefreshCount + 1.
	^ super initializeServerOffsets
]

{ #category : 'accessing' }
CoreGbsCountingReplicator >> serverOffsetRefreshCount [
	^ serverOffsetRefreshCount ifNil: [ 0 ]
]
