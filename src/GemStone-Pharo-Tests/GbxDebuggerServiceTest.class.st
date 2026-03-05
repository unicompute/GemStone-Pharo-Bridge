Class {
	#name : 'GbxDebuggerServiceTest',
	#superclass : 'TestCase',
	#instVars : [
		'service',
		'session',
		'context'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxDebuggerServiceTest >> setUp [
	super setUp.
	GbxFakeInspectorForService reset.
	GbxFakeBreakPointForService reset.
	GbxFakeBrowserForService reset.
	session := MockGbsSession new.
	service := GbxTestableDebuggerService new.
	service session: session.
	context := GbxFakeActivationForService new.
	context
		processOop: 111;
		level: 3;
		selector: #foo;
		methodClass: 'DemoClass';
		sourceOffsets: #(10 20 30).
	service currentContext: context.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentProcessUsesContextProcessOop [
	| opened |
	opened := service inspectCurrentProcess.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 111.
	self assert: GbxFakeInspectorForService lastSession == session.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverUsesDetailedReportOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_gsiDebuggerDetailedReportAt:')
				ifTrue: [ '222' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentReceiver.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 222.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentFrameUsesFrameContentsOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_frameContentsAt:')
				ifTrue: [ '333' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentFrame.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 333.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverReturnsFalseWhenNoContext [
	service currentContext: nil.

	self deny: service inspectCurrentReceiver.
	self assert: GbxFakeInspectorForService lastOop isNil.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testBreakpointsInSelectedMethodFiltersBySelectorAndClass [
	| match noMatchSelector noMatchClass found |
	match := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	noMatchSelector := GbxFakeBreakPointForService
		selector: #bar
		remoteClass: 'DemoClass'
		stepPoint: 2.
	noMatchClass := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'OtherClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { match. noMatchSelector. noMatchClass }.

	found := service breakpointsInSelectedMethod.
	self assert: found size equals: 1.
	self assert: found first == match.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testSetBreakPointInDelegatesToBrowserClass [
	| widget |
	widget := GbxFakeTextWidgetForService new.
	widget selectionInterval: (1 to: 1).

	self assert: (service setBreakPointIn: widget).
	self assert: GbxFakeBrowserForService lastBreakView == widget.
	self assert: GbxFakeBrowserForService lastModel == context.
	self assert: GbxFakeBrowserForService lastMethod equals: #foo.
	self assert: GbxFakeBrowserForService lastClass equals: 'DemoClass'.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveBreakPointClearsFirstMatchingBreakpoint [
	| bp1 bp2 |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	self assert: service removeBreakPoint.
	self assert: bp1 cleared.
	self deny: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveBreakInClearsBreakpointMatchingSelectionOffset [
	| bp1 bp2 widget |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	widget := GbxFakeTextWidgetForService new.
	widget selectionInterval: (19 to: 21). "Matches stepPoint 2 => offset 20"

	self assert: (service removeBreakIn: widget).
	self deny: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveAllBreakPointsClearsAllMatching [
	| bp1 bp2 removedCount |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	removedCount := service removeAllBreakPoints.
	self assert: removedCount equals: 2.
	self assert: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCanRemoveBreakPointReflectsExistingMethodBreakpoints [
	| bp |
	self deny: service canRemoveBreakPoint.

	bp := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	GbxFakeBreakPointForService breakPointList: { bp }.

	self assert: service canRemoveBreakPoint.
	self assert: service canRemoveAllBreakPoints.
]
