Class {
	#name : #'GbxNullReplicationScheme',
	#superclass : #'GbxAbstractReplicationScheme',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxNullReplicationScheme >> indexedInstvarsShouldBeForwardersInClass: clientClass
	"unsynchronized replication is only valid for a few classes, which do not replicate their instvars as forwarders."

	^false

{ #category : #'accessing' }
GbxNullReplicationScheme >> forwarderOffsetsForClass: clientClass
	"Always false for all offsets, all classes, for the null scheme."

	^GbxNullForwarderOffsets

{ #category : #'accessing' }
GbxNullReplicationScheme >> selector
	"Used for printing."

	^'nil'

{ #category : #'testing' }
GbxNullReplicationScheme >> isValid

	^true

{ #category : #'testing' }
GbxNullReplicationScheme >> usesClamps

	^false

