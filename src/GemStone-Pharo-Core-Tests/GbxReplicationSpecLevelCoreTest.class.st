"
Headless tests for the VisualWorks clamp/replicator spec level-resolution semantics on GbxReplicationScheme.
A per-instvar replication spec element is a two- or three-element array whose operator (slot 2) maps to a
client-side traversal level code via #instVarLevelForReplicationSpec:: #forwarder -> false (proxy the slot),
#stub -> 0, #replicate -> nil (fully replicate), #max:n -> a non-negative clamp level (negatives floor to 0),
and #min:n -> a negated level for n>0 or nil for n<=0. #shouldBeForwarderForReplicationSpec: reports the
#forwarder operator. These are the pure decisions a <selector>GbsClampCallback drives per slot, so they are
worth pinning independently of a live stone.
"
Class {
	#name : 'GbxReplicationSpecLevelCoreTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'support' }
GbxReplicationSpecLevelCoreTest >> scheme [
	^ GbxReplicationScheme replicate
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testForwarderOperatorProducesProxyLevel [
	"#forwarder means the slot is a proxy/forwarder; its level code is false."
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #forwarder)) equals: false.
	self assert: (self scheme shouldBeForwarderForReplicationSpec: #(#aSlot #forwarder)).
	self deny: (self scheme shouldBeForwarderForReplicationSpec: #(#aSlot #replicate))
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testStubOperatorProducesZeroLevel [
	"#stub clamps the slot to level 0 (materialize the object itself, none of its referents)."
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #stub)) equals: 0
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testReplicateOperatorProducesNilLevel [
	"#replicate means fully replicate (no clamp); its level code is nil."
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #replicate)) isNil
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testMaxOperatorClampsToNonNegativeLevel [
	"#max: n clamps to a positive depth n; a negative n floors to 0."
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #max 3)) equals: 3.
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #max 0)) equals: 0.
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #max -2)) equals: 0
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testMinOperatorNegatesPositiveLevelAndNilsNonPositive [
	"#min: n encodes a minimum depth as a negated level for n>0, and nil (no minimum) for n<=0."
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #min 2)) equals: -2.
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #min 0)) isNil.
	self assert: (self scheme instVarLevelForReplicationSpec: #(#aSlot #min -4)) isNil
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testIllegalOperatorIsRejected [
	"An unknown operator is a malformed spec and must error rather than silently mis-clamp."
	self
		should: [ self scheme instVarLevelForReplicationSpec: #(#aSlot #bogusOperator) ]
		raise: Error
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testDictionaryFormKeysSpecsByServerSlotName [
	"A replication spec (a collection of per-slot arrays) is indexed by the first element as a string;
	a bare symbol spec (e.g. #callback) yields no per-slot dictionary entries."
	| specs |
	specs := self scheme dictionaryFormOfReplicationSpec: { #(#alpha #forwarder). #(#beta #max 2) }.
	self assert: (specs at: 'alpha') equals: #(#alpha #forwarder).
	self assert: (specs at: 'beta') equals: #(#beta #max 2).
	self assert: (self scheme dictionaryFormOfReplicationSpec: #callback) isEmpty
]

{ #category : 'tests' }
GbxReplicationSpecLevelCoreTest >> testDictionaryFormRejectsMalformedSpecElement [
	"Each spec element must be a two- or three-element array."
	self
		should: [ self scheme dictionaryFormOfReplicationSpec: { #(#alpha) } ]
		raise: Error
]
