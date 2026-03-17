Class {
	#name : #'GbsMemoryPolicy',
	#superclass : #'LargeGrainMemoryPolicy',
	#instVars : [ #'needIncrementalReclamation' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'incremental GC' }
GbsMemoryPolicy >> incrementalReclamation
	"Defer inc GC until we're not in replication"

	GBSM hasSessionsInInteractions
		ifFalse: [super incrementalReclamation]
		ifTrue: [needIncrementalReclamation := true]

{ #category : #'GBS-specific' }
GbsMemoryPolicy >> postReplicationAction

	needIncrementalReclamation
		ifTrue: 
			[self fullReclamation.
			needIncrementalReclamation := false]

{ #category : #'private - IGC' }
GbsMemoryPolicy >> igcObjects: anInteger interruptably: aBoolean

	ObjectMemory
		primMeasureIGCIsInterruptible: aBoolean
		objects: anInteger
		bytes: 536870911

{ #category : #'install/deinstall' }
GbsMemoryPolicy >> noticeOfInstall
	"When a GbsMemoryPolicy or a subclass is installed as the current memory policy, it must also be the memory policy that GBSM knows about. When the current system memory policy is a non-GBS policy, GBSM's policy must still be a GBS policy, though it won't do much."

	GBSM memoryPolicy: self

{ #category : #'private' }
GbsMemoryPolicy >> fullReclamation
	"Run the incremental garbage collector from start to finish. If it aborts, do a stop-the-world GC."

	memoryStatus incGCIsResting
		ifFalse: 
			[memoryStatus incGCIsMarking
				ifTrue: [memoryStatus class abortOrFinishIncrementalGC	"This will abort"]
				ifFalse: 
					[
					[self igcObjects: nil interruptably: false.
					self updateMemoryStatus.
					memoryStatus incGCIsResting or: [memoryStatus incGCIsAborting]]
							whileFalse]].
	memoryStatus incGCIsAborting
		ifTrue: [self basicCompactingGC	"IGC failed, just hit it with the big hammer"]
		ifFalse: 
			["Do an incGC until done"
			
			[self igcObjects: nil interruptably: false.
			self updateMemoryStatus.
			memoryStatus incGCIsResting or: [memoryStatus incGCIsAborting]]
					whileFalse].
	memoryStatus incGCIsAborting
		ifTrue: [self basicCompactingGC	"IGC failed, hit it with the big hammer"].
	self updateNumScavengesAsOfLastGC.
	ObjectMemory softLowSpaceLimit: self newSoftLowSpaceLimit

{ #category : #'private' }
GbsMemoryPolicy >> initialize

	super initialize.
	needIncrementalReclamation := false.

