Class {
	#name : 'GbxActivationTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxActivationTest >> testVisibleSourceMapHighlightsAssignmentToken [
	| activation map |
	activation := GbxActivationTool new.
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
	activation := GbxActivationTool new.
	activation sourceString: 'a ~~ b'.
	activation sourceOffsets: #(3).

	map := activation visibleSourceMap.

	self assert: map size equals: 1.
	self assert: map first value equals: (3 to: 4).
]

{ #category : 'tests' }
GbxActivationTest >> testVisibleSourceMapSkipsNilAndOutOfBoundsOffsets [
	| activation map |
	activation := GbxActivationTool new.
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
	activation := GbxActivationTool new.
	activation sourceString: 'x := y + z'.
	activation sourceOffsets: #(1 6 10).

	self assert: (activation sourceIntervalForStepPoint: 2) equals: (6 to: 6).
	self assert: (activation sourceIntervalForStepPoint: 99) isNil
]

{ #category : 'tests' }
GbxActivationTest >> testExecutedCodePrintStringIncludesStepAndLine [
	| activation |
	activation := GbxActivationTool new.
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
	activation := GbxActivationTool new.
	activation
		methodClass: 'nil';
		selector: #nil;
		level: 8;
		sourceString: '| a b |', String lf, 'a := 10.'.

	self assert: activation printString equals: 'GS: Executed code @8'
]

{ #category : 'tests' }
GbxActivationTest >> testResetUsesDetailedReportFrameDirectly [
	| activation session capturedScript |
	activation := GbxActivationTool new.
	session := MockGbsSession new.
	session stubs at: #evaluate put: [ :script |
		capturedScript := script.
		'DemoClass|foo|2|10,20|arg,temp|foo ^ 1|7|2|3|DemoClass|aReceiver|DemoReceiver|selfValue' ].

	activation
		session: session;
		processOop: 111;
		level: 1.

	activation reset.

	self deny: (capturedScript includesSubstring: 'fullEntry := frame first').
	self assert: activation methodClass equals: 'DemoClass'.
	self assert: activation selector equals: #foo.
	self assert: activation receiverClass equals: 'DemoReceiver'
]
