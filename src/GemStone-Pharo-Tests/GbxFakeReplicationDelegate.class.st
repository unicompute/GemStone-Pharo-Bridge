Class {
	#name : 'GbxFakeReplicationDelegate',
	#superclass : 'Object',
	#instVars : [
		'dirty',
		'exportedCount'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeReplicationDelegate >> dirty: aBoolean [
	dirty := aBoolean
]

{ #category : 'accessing' }
GbxFakeReplicationDelegate >> exportedCount [
	^ exportedCount ifNil: [ 0 ]
]

{ #category : 'replication' }
GbxFakeReplicationDelegate >> forSession: aSession [
	^ self
]

{ #category : 'replication' }
GbxFakeReplicationDelegate >> isStDirty [
	^ dirty ifNil: [ false ]
]

{ #category : 'replication' }
GbxFakeReplicationDelegate >> nowExported [
	exportedCount := self exportedCount + 1
]
