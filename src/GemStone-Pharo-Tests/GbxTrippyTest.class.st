Class {
	#name : 'GbxTrippyTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxTrippyTest >> testGoBackAndForwardTrackNavigationHistory [
	| trippy |
	trippy := GbxTestableTrippy new.

	trippy inspectOop: 10.
	trippy navigateTo: { 'child'. 'Array'. 'value'. 20 }.
	trippy navigateTo: { 'grandchild'. 'Array'. 'value'. 30 }.

	self assert: trippy currentOop equals: 30.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 30).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty.

	trippy goBack.
	self assert: trippy currentOop equals: 20.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20).
	self assert: (trippy instVarNamed: 'forwardStack') asArray equals: #(30).

	trippy goForward.
	self assert: trippy currentOop equals: 30.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 30).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty.
	self assert: trippy showCurrentObjectCalls equals: 5
]

{ #category : 'tests' }
GbxTrippyTest >> testNavigateToClearsForwardHistory [
	| trippy |
	trippy := GbxTestableTrippy new.

	trippy inspectOop: 10.
	trippy navigateTo: { 'child'. 'Array'. 'value'. 20 }.
	trippy navigateTo: { 'grandchild'. 'Array'. 'value'. 30 }.
	trippy goBack.
	trippy navigateTo: { 'replacement'. 'Array'. 'value'. 40 }.

	self assert: trippy currentOop equals: 40.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 40).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty
]
