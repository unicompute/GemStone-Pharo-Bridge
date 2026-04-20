Class {
	#name : 'GbxActivationTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
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

{ #category : 'tests' }
GbxActivationTest >> testExecutedCodePrintStringIncludesStepAndLine [
	| activation |
	activation := GbxActivation new.
	activation
		methodClass: 'nil';
		selector: #nil;
		level: 8;
		quickStepPoint: 3;
		sourceString: '| a b |', String lf, 'a := 10.', String lf, 'b := 0.', String lf, 'a / b';
		sourceOffsets: #(1 9 12 26).

	self assert: activation printString equals: 'GS: Executed code @3 line 2'
]

{ #category : 'tests' }
GbxActivationTest >> testExecutedCodePrintStringFallsBackToLevelWhenStepPointMissing [
	| activation |
	activation := GbxActivation new.
	activation
		methodClass: 'nil';
		selector: #nil;
		level: 8;
		sourceString: '| a b |', String lf, 'a := 10.'.

	self assert: activation printString equals: 'GS: Executed code @8'
]
