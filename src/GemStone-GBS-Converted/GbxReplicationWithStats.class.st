Class {
	#name : #'GbxReplicationWithStats',
	#superclass : #'GbxReplication',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private' }
GbxReplicationWithStats >> replicateFromTraversalReport: report
	"If reportsWithNoMappedClass is nil, we're on the second pass - this object has already been counted"
	"The sender must hold my session protect."

	reportsWithNoMappedClass isNil
		ifFalse: [session statResource incObjectsTraversed].
	^super replicateFromTraversalReport: report

