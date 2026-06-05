"
Headless tests for the VisualWorks connector subclasses ported into the bridge: GbsClassVarConnector,
GbsClassInstVarConnector, and GbsFastConnector. Exercises the accessors, constructors, gsvarName fallback,
the association/value distinction, and descriptions without a live session.
"
Class {
	#name : 'GbsConnectorSubclassTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests - class var' }
GbsConnectorSubclassTest >> testClassVarConnectorSameNameBothSides [
	| c |
	c := GbsClassVarConnector stName: 'Account' gsName: 'GsAccount' cvarName: 'Total'.
	self assert: c stName equals: 'Account'.
	self assert: c gsName equals: 'GsAccount'.
	self assert: c cvarName equals: 'Total'.
	self assert: c gsvarName equals: 'Total'.
	self assert: c stvarName equals: #Total.
	self assert: c variableName equals: #Total.
	self assert: c connectsAssociation
]

{ #category : 'tests - class var' }
GbsConnectorSubclassTest >> testClassVarConnectorDistinctNames [
	| c |
	c := GbsClassVarConnector stName: 'Account' gsName: 'GsAccount' stvarName: 'Total' gsvarName: 'GsTotal'.
	self assert: c cvarName equals: 'Total'.
	self assert: c gsvarName equals: 'GsTotal'.
	self assert: c stvarName equals: #Total.
	self assert: c variableName equals: #GsTotal
]

{ #category : 'tests - class var' }
GbsConnectorSubclassTest >> testClassVarConnectorGsvarNameFallsBackToCvar [
	| c |
	c := GbsClassVarConnector new cvarName: 'Total'; yourself.
	self assert: c gsvarName equals: 'Total'.
	c gsvarName: 'Override'.
	self assert: c gsvarName equals: 'Override'.
	c gsvarName: nil.
	self assert: c gsvarName equals: 'Total'
]

{ #category : 'tests - class var' }
GbsConnectorSubclassTest >> testClassVarConnectorDescriptions [
	| c |
	c := GbsClassVarConnector stName: 'Account' gsName: 'GsAccount' stvarName: 'Total' gsvarName: 'GsTotal'.
	self assert: (c stDescription includesSubstring: 'Account').
	self assert: (c stDescription includesSubstring: 'Total').
	self assert: (c gsDescription includesSubstring: 'GsAccount').
	self assert: (c gsDescription includesSubstring: 'GsTotal')
]

{ #category : 'tests - class inst var' }
GbsConnectorSubclassTest >> testClassInstVarConnectorDoesNotConnectAssociation [
	| c |
	c := GbsClassInstVarConnector stName: 'Account' gsName: 'GsAccount' cvarName: 'Default'.
	self deny: c connectsAssociation.
	self assert: c variableKind equals: #classInstanceVariable.
	self assert: c cvarName equals: 'Default'.
	self assert: (c gsDescription includesSubstring: 'class>>')
]

{ #category : 'tests - fast' }
GbsConnectorSubclassTest >> testFastConnectorBindsClientObjectAndServerOop [
	| client c |
	client := Object new.
	c := GbsFastConnector stObj: client gsObj: 9201.
	self assert: c clientObj identicalTo: client.
	self assert: c serverKernelOop equals: 9201.
	self assert: (c gsDescription includesSubstring: '9201')
]

{ #category : 'tests - fast' }
GbsConnectorSubclassTest >> testFastConnectorResolvesOopFromObjectAnsweringOop [
	"stObj:gsObj: should read the OOP from any object answering #oop, not just a raw integer. A
	GbsFastConnector itself answers #serverKernelOop, not #oop, so use a minimal #oop responder."
	| client holder c |
	client := Object new.
	holder := GbsConnectorSubclassOopHolder new oop: 5005.
	c := GbsFastConnector stObj: client gsObj: holder.
	self assert: c serverKernelOop equals: 5005
]
