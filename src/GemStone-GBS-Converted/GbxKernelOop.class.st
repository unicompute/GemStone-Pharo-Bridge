Class {
	#name : 'GbxKernelOop',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'GemStone extensions' }
GbxKernelOop >> performOnGsServer: aSelector withArguments: argArray

	^(self asGSObjectInSession: GBSM currentSession) performOnGsServer: aSelector withArguments: argArray

{ #category : 'comparing' }
GbxKernelOop >> = anObject 
	self == anObject ifTrue: [^true].
	anObject isGSObject ifFalse: [^false].
	(anObject isKindOf: GbxKernelOop) ifTrue: [^false].	"If equal, should be identical"
	^(self asGSObjectInSession: anObject session) sameOopAs: anObject

{ #category : 'comparing' }
GbxKernelOop >> equalsDelegate: aDelegate 
	^(self asGSObjectInSession: aDelegate session) sameOopAs: aDelegate

{ #category : 'comparing' }
GbxKernelOop >> hash

	self subclassResponsibility

{ #category : 'implicit replication' }
GbxKernelOop >> asLocalObject
	^(self asGSObjectInSession: GBSM currentSession) asLocalObject

{ #category : 'testing' }
GbxKernelOop >> isGSObject
	^true

{ #category : 'testing' }
GbxKernelOop >> gbxCanBeArgForUnsynchronizedOperationInSession: session

	^true

{ #category : 'remote execution' }
GbxKernelOop >> remotePerform: aSelector 
	^(self asGSObjectInSession: GBSM currentSession) remotePerform: aSelector

{ #category : 'remote execution' }
GbxKernelOop >> remotePerform: aSelector with: anArg 
	^(self asGSObjectInSession: GBSM currentSession) remotePerform: aSelector
		with: anArg

{ #category : 'remote execution' }
GbxKernelOop >> remotePerform: aSelector with: anArg with: argTwo with: argThree 
	^(self asGSObjectInSession: GBSM currentSession) 
		remotePerform: aSelector
		with: anArg
		with: argTwo
		with: argThree

{ #category : 'remote execution' }
GbxKernelOop >> remotePerform: aSelector withArgs: argArray 
	^(self asGSObjectInSession: GBSM currentSession) remotePerform: aSelector
		withArgs: argArray

{ #category : 'remote execution' }
GbxKernelOop >> remotePerform: aSelector with: anArg with: argTwo 
	^(self asGSObjectInSession: GBSM currentSession) 
		remotePerform: aSelector
		with: anArg
		with: argTwo

{ #category : 'private' }
GbxKernelOop >> forAnySingleSession
	| sess |
	sess := GBSM currentSessionIfNone: [].
	^sess == nil ifTrue: [nil] ifFalse: [self asGSObjectInSession: sess]

