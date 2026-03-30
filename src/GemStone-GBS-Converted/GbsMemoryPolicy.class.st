Class {
	#name : 'GbsMemoryPolicy',
	#superclass : 'Object',
	#instVars : [
		'needIncrementalReclamation'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'reclamation' }
GbsMemoryPolicy >> fullReclamation [
	Smalltalk garbageCollect.
	needIncrementalReclamation := false
]

{ #category : 'reclamation' }
GbsMemoryPolicy >> igcObjects: anInteger interruptably: aBoolean [
	^ Smalltalk garbageCollect
]

{ #category : 'initialization' }
GbsMemoryPolicy >> initialize [
	super initialize.
	needIncrementalReclamation := false
]

{ #category : 'reclamation' }
GbsMemoryPolicy >> incrementalReclamation [
	GBSM hasSessionsInInteractions
		ifTrue: [ needIncrementalReclamation := true ]
		ifFalse: [ self fullReclamation ]
]

{ #category : 'installing' }
GbsMemoryPolicy >> noticeOfInstall [
	GBSM memoryPolicy: self
]

{ #category : 'reclamation' }
GbsMemoryPolicy >> postReplicationAction [
	needIncrementalReclamation ifTrue: [ self fullReclamation ]
]
