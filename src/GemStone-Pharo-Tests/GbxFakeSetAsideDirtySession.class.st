"
A minimal session double for exercising GbxDirtyPool>>setAsideDirtyWhile:. It records how many times
flushDirtyMaterializedObjects is invoked and, on each flush, drains the pool's current dirty set into
flushedObjects, mirroring what a real GbsSession flush does to dirtyAwaitingPacking.
"
Class {
	#name : 'GbxFakeSetAsideDirtySession',
	#superclass : 'Object',
	#instVars : [
		'dirtyPool',
		'flushCount',
		'flushedObjects'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeSetAsideDirtySession >> dirtyPool [
	^ dirtyPool ifNil: [ dirtyPool := GbxDirtyPool forSession: self ]
]

{ #category : 'accessing' }
GbxFakeSetAsideDirtySession >> flushCount [
	^ flushCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeSetAsideDirtySession >> flushedObjects [
	^ flushedObjects ifNil: [ flushedObjects := OrderedCollection new ]
]

{ #category : 'flushing' }
GbxFakeSetAsideDirtySession >> flushDirtyMaterializedObjects [
	| pool |
	flushCount := self flushCount + 1.
	pool := self dirtyPool.
	self flushedObjects addAll: pool dirtyAwaitingPacking.
	pool clearDirty.
	^ #()
]
