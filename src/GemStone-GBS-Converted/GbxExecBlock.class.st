Class {
	#name : 'GbxExecBlock',
	#superclass : 'Object',
	#instVars : [
		'method'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxExecBlock >> printNameOn: aStream inClass: aClass
[

]

{ #category : 'gemstone private' }
GbxExecBlock >> gbxIsThisLastReport: report
[

	"Blocks don't use standard replication, and will never require a moreTraversal."
	^true
]

{ #category : 'GBS private' }
GbxExecBlock class >> gbsReplicatorClass
[

	^GbxBlockReplicator
]

{ #category : 'gemstone private' }
GbxExecBlock class >> gbsClassUnloading
[

	CallbackOverrides := ReplicateOverrides := nil.
]

{ #category : 'gemstone private' }
GbxExecBlock class >> gbxBlockClass
[

	^BlockClosure
]

{ #category : 'gemstone private' }
GbxExecBlock class >> gbxCompileSource: source
[
	"GBS"

	| compiler |
	compiler := self gbxResolve: #Compiler in: #Kernel.
	compiler isNil
		ifTrue: 
			[^self
				blockReplicationError: 'Block replication failed because Compiler isn''t present in this image.'].
	^compiler evaluate: source
]

{ #category : 'gemstone private' }
GbxExecBlock class >> instVarMap
[
	"Need to map the _method instvar, which trav by callback replaces with the source string,
	or it will be clamped. We don't actually assign this to the method instvar in the client, we
	compile it first."

	^super instVarMap , #(#(#method #_method))
]

{ #category : 'gemstone private' }
GbxExecBlock class >> isCallbackOverride: aBlock
[

	(CallbackOverrides includes: aBlock)
		ifTrue: [
			CallbackOverrides remove: aBlock.
			^true ]
		ifFalse: [ ^false ]
]

{ #category : 'gemstone private' }
GbxExecBlock class >> addCallbackOverride: aBlock
[

	CallbackOverrides add: aBlock
]

{ #category : 'gemstone private' }
GbxExecBlock class >> initialize
[
	"GbxExecBlock initialize"

	CallbackOverrides := IdentitySet new.
	ReplicateOverrides := IdentitySet new
]

{ #category : 'gemstone private' }
GbxExecBlock class >> newFromGSObjectReport: report inSession: session
[
	"GBS.  GemStone places the oop of the block's source string into the first slot of
	 the report.  The string is placed in the traversal buffer before the block's report."
	"Sender must hold session's sessionProtect"

	| src blk oop |
	GbsConfiguration current blockReplicationEnabled
		ifFalse: [^self blockReplicationError: 'Block replication is disabled.'].

	oop := report oopPtrAt: 1.
	src := session clientObjForDelegate: oop otherwise: nil.
	src isString
		ifFalse: [^self blockReplicationError: 'Block replication failed - source string not in traversal buffer'].

	blk := self gbxCompileSource: src.
	(blk isKindOf: self gbxBlockClass)
		ifFalse: [^self blockReplicationError: 'Block replication from GemStone to Smalltalk failed.'].

	^blk
]

{ #category : 'gemstone private' }
GbxExecBlock class >> isReplicateOverride: aBlock
[

	(ReplicateOverrides includes: aBlock)
		ifTrue: [
			ReplicateOverrides remove: aBlock.
			^true ]
		ifFalse: [ ^false ]
]

{ #category : 'gemstone private' }
GbxExecBlock class >> addReplicateOverride: aBlock
[

	ReplicateOverrides add: aBlock
]

{ #category : 'gemstone private' }
GbxExecBlock class >> replicationSpec
[
	"The server uses traversal by callback to traverse the source string,
	which appears in slot 1, actually the '_method' instvar on the server.
	So we always get the string, specify replication of method. "

	^super replicationSpec , #(#( #method #min 1))
]

{ #category : 'gemstone private' }
GbxExecBlock class >> blockReplicationError: aString
[

	self gbsMessenger raise: GbsBlockReplicationError message: aString
]

{ #category : 'gemstone private' }
GbxExecBlock class >> blockReplicationPolicyFor: aBlock 
[
	"Returns #replicate or #callback"

	GbsConfiguration current blockReplicationPolicy == #replicate 
		ifTrue: 
			["Default is #replicate - does this block override?"

			(self isCallbackOverride: aBlock) 
				ifTrue: [^#callback]
				ifFalse: [^#replicate]]
		ifFalse: 
			["Default is #callback - does this block override?"

			(self isReplicateOverride: aBlock) 
				ifTrue: [^#replicate]
				ifFalse: [^#callback]]
]

{ #category : 'gemstone private' }
GbxExecBlock class >> canUnstubInPlaceFromReport: report stubSize: stubSize
[

	"Blocks can't unstub in place - a new client block must be generated
	 by the compiler."
	^false
]

