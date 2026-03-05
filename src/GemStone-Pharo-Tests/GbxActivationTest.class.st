Class {
	#name : 'GbxActivationTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxActivationTest >> testVisibleSourceMapHighlightsAssignmentToken [
	| activation map |
	activation := GbxActivation new.
	activation sourceString: '^ x := y + z'.
	activation sourceOffsets: #(5).

	map := activation visibleSourceMap.

	self assert: map size equals: 1.
	self assert: map first key equals: 1.
	self assert: map first value equals: (5 to: 6).
]

{ #category : 'tests' }
GbxActivationTest >> testVisibleSourceMapHighlightsBinaryTokenSpan [
	| activation map |
	activation := GbxActivation new.
	activation sourceString: 'a ~~ b'.
	activation sourceOffsets: #(3).

	map := activation visibleSourceMap.

	self assert: map size equals: 1.
	self assert: map first value equals: (3 to: 4).
]

{ #category : 'tests' }
GbxActivationTest >> testVisibleSourceMapSkipsNilAndOutOfBoundsOffsets [
	| activation map |
	activation := GbxActivation new.
	activation sourceString: 'abc'.
	activation sourceOffsets: { nil. 0. 4. 2 }.

	map := activation visibleSourceMap.

	self assert: map size equals: 1.
	self assert: map first key equals: 4.
	self assert: map first value equals: (2 to: 3).
]

{ #category : 'tests' }
GbxActivationTest >> testSourceIntervalForStepPoint [
	| activation |
	activation := GbxActivation new.
	activation sourceString: 'x := y + z'.
	activation sourceOffsets: #(1 6 10).

	self assert: (activation sourceIntervalForStepPoint: 2) equals: (6 to: 6).
	self assert: (activation sourceIntervalForStepPoint: 99) isNil
]
