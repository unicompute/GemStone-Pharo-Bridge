Class {
	#name : #'GbxAbstractReplicationScheme',
	#superclass : #'Object',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxAbstractReplicationScheme >> selector
	"Answer the selector which 'names' the replication scheme."

	^self subclassResponsibility

{ #category : #'accessing' }
GbxAbstractReplicationScheme >> indexedInstvarsShouldBeForwardersInClass: clientClass
	"Answer whether the indexed instance variables of instances
	 of a clientClass should be forwarders."

	^self subclassResponsibility

{ #category : #'accessing' }
GbxAbstractReplicationScheme >> forwarderOffsetsForClass: clientClass
	"Answer a sequence of Booleans indicating whether each named
	 instance variable of instances of a clientClass should be forwarders."

	^self subclassResponsibility

{ #category : #'testing' }
GbxAbstractReplicationScheme >> usesClamps
	"Answer whether this replication scheme uses clamps."

	^self subclassResponsibility

