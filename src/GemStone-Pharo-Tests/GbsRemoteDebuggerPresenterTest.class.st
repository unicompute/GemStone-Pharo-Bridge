Class {
	#name : 'GbsRemoteDebuggerPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'debugger',
		'service'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerPresenterTest >> setUp [
	super setUp.
	debugger := TestableGbsRemoteDebugger new.
	service := GbxFakeServiceForRemoteDebugger new.
	debugger service: service.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectReceiverDelegatesToService [
	self assert: debugger inspectReceiver.
	self assert: service inspectReceiverCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectProcessDelegatesToService [
	self assert: debugger inspectProcess.
	self assert: service inspectProcessCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectFrameDelegatesToService [
	self assert: debugger inspectFrame.
	self assert: service inspectFrameCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectStackFallsBackToFrameInspectionServiceCall [
	self assert: debugger inspectStack.
	self assert: service inspectFrameCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectReceiverReturnsFalseWhenServiceRaises [
	service raiseOnInspectReceiver: true.

	self deny: debugger inspectReceiver.
	self assert: service inspectReceiverCalls equals: 0.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectVariableDelegatesSelectedVariableNameToService [
	| fakeTable |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: #('a' '10').
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	self assert: debugger inspectVariable.
	self assert: service inspectVariableCalls equals: 1.
	self assert: service lastInspectedVariableName equals: 'a'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectVariableReturnsFalseWhenNoSelection [
	| fakeTable |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	self deny: debugger inspectVariable.
	self assert: service inspectVariableCalls equals: 0
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| session |
	session := MockGbsSession new.
	debugger session: session.
	debugger enqueueRequestAnswer: 'abc'.

	self deny: debugger browsePromptedSessionStateKey.
	self assert: debugger lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: debugger lastInspectedOop isNil
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9501 session: session ].
	debugger session: session.
	debugger enqueueRequestAnswer: '21'.

	self assert: debugger browsePromptedSessionStateKey.
	self assert: debugger lastInspectedOop equals: 9501.
	self assert: debugger lastInspectedSession == session
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseRubyLoadPathReport.
	self assert: (debugger lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (debugger lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseRubyLoadedFeaturesReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (debugger lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseRubyPersistentLoadedFeaturesReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (debugger lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseTopLevelAutoloadRegistrationsReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (debugger lastInfoMessage includesSubstring: 'DemoConst -> demo/file [Pending]')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyRuntimeProvenanceGraphUsesRuntimeReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseRubyRuntimeProvenanceGraph.
	self assert: (debugger lastInfoMessage includesSubstring: 'Ruby Runtime Provenance').
	self assert: (debugger lastInfoMessage includesSubstring: 'Transient Feature -> app/models/invoice.rb')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyRuntimeProvenanceBrowserOpensStructuredGraph [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.

	self assert: debugger browseRubyRuntimeProvenanceBrowser.
	self assert: debugger lastInfoMessage equals: 'Ruby Runtime Provenance'.
	self assert: debugger lastProvenanceGraph notNil.
	self assert: debugger lastProvenanceGraph browserRows size > 0
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseRubyRuntimeProvenanceActionChooserExecutesSelectedAction [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''app/models/invoice.rb'' env: 1')
			ifTrue: [ ^ 'required' ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	debugger session: session.
	debugger enqueueChooseAnswer: 1.

	self assert: debugger browseRubyRuntimeProvenanceActionChooser.
	self assert: (debugger lastInfoMessage includesSubstring: 'Executed require app/models/invoice.rb => ''required''').
	self assert: (debugger lastInfoMessage includesSubstring: 'Ruby Runtime Provenance')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseStaleTypedWrapperLifecycleReportUsesStaleEntries [
	| session stale current |
	session := MockGbsSession new.
	stale := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'DemoClient'
		serverName: 'DemoServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 2
		remoteNumberOfVersions: 2
		status: #stale.
	current := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'FreshClient'
		serverName: 'FreshServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 1
		remoteNumberOfVersions: 1
		status: #current.
	session stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { stale. current } ].
	debugger session: session.

	self assert: debugger browseStaleTypedWrapperLifecycleReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (debugger lastInfoMessage includesSubstring: 'DemoClient').
	self deny: (debugger lastInfoMessage includesSubstring: 'FreshClient')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ 'cache' ].
		self fail ].
	debugger session: session.
	debugger enqueueRequestAnswer: '19, 21'.

	self assert: debugger browsePromptedSessionStateKeysReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Session State').
	self assert: (debugger lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: (debugger lastInfoMessage includesSubstring: 'Key 21 (Session State): ByteString')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		^ { GbsProxy oop: 9101 session: session. GbsProxy oop: 9102 session: session } ].
	debugger session: session.
	debugger enqueueRequestAnswer: '3'.
	debugger enqueueRequestAnswer: '2'.

	self assert: debugger browseObjectsInMemoryReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (debugger lastInfoMessage includesSubstring: 'oop=9101').
	self assert: (debugger lastInfoMessage includesSubstring: 'oop=9102')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsReport [
	| session |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ GbsProxy oop: 9191 session: session ].
		(script includesSubstring: 'findReferencesInMemory')
			ifTrue: [ ^ { GbsProxy oop: 9292 session: session } ].
		self fail ].
	debugger session: session.

	self assert: debugger browseMaglevFinalizerRegistryReport.
	self assert: (debugger lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9191 Referencers').
	self assert: (debugger lastInfoMessage includesSubstring: 'oop=9292')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSetBreakPointDelegatesToService [
	self assert: debugger setBreakPoint.
	self assert: service setBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testToggleBreakPointDelegatesToService [
	self assert: debugger toggleBreakPoint.
	self assert: service toggleBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsDoItDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '1 + 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsDoIt.
	self assert: service gsDoItCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsPrintItDelegatesToServiceAndAppendsResult [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '21+21'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsPrintIt.
	self assert: service gsPrintItCalls equals: 1.
	self assert: (fakeText text includesSubstring: '"42"').
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsInspectItDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'Array new'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsInspectIt.
	self assert: service gsInspectItCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testServerMethodReferencesForImplementorsUsesSessionFacadeOutsideHierarchy [
	| session references |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Non-hierarchy implementor queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'organizer implementorsOf: #size').
			^ #('Object>>size') ].
	debugger session: session.

	references := debugger
		serverMethodReferencesFor: #size
		hierarchyOnly: false
		senders: false.

	self assert: references equals: #('Object>>size')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testServerMethodReferencesForSendersUsesSessionFacadeOutsideHierarchy [
	| session references |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Non-hierarchy sender queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'organizer sendersOf: ''size''').
			^ #('Behavior>>new') ].
	debugger session: session.

	references := debugger
		serverMethodReferencesFor: #size
		hierarchyOnly: false
		senders: true.

	self assert: references equals: #('Behavior>>new')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testServerMethodReferencesForHierarchyImplementorsUsesSessionFacade [
	| session references context |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Hierarchy implementor queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'className := ''Invoice class''').
			self assert: (script includesSubstring: 'baseName := className copyFrom: 1 to: className size - 6').
			self assert: (script includesSubstring: 'objectNamed: baseName asSymbol) class').
			self assert: (script includesSubstring: 'cls class includesSelector: sel').
			^ #('Invoice class>>new') ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice class'.
	context selector: #new.
	service currentContext: context.
	debugger session: session.

	references := debugger
		serverMethodReferencesFor: #new
		hierarchyOnly: true
		senders: false.

	self assert: references equals: #('Invoice class>>new')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testServerMethodReferencesForHierarchySendersUsesSessionFacade [
	| session references context |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Hierarchy sender queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'className := ''Invoice''').
			self assert: (script includesSubstring: 'objectNamed: className asSymbol').
			self assert: (script includesSubstring: 'cls class whichSelectorsReferTo: sel').
			^ #('Invoice class>>buildDefault') ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #size.
	service currentContext: context.
	debugger session: session.

	references := debugger
		serverMethodReferencesFor: #size
		hierarchyOnly: true
		senders: true.

	self assert: references equals: #('Invoice class>>buildDefault')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSelectedServerReferenceTargetNameStripsClassSideSuffix [
	| context |
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice class'.
	context selector: #new.
	service currentContext: context.

	self assert: debugger selectedServerReferenceTargetName equals: 'Invoice'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testServerClassReferenceStringsUsesSessionFacade [
	| session references context |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Class reference queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'organizer referencesTo: #Invoice').
			^ #('Invoice>>totalPrice') ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice class'.
	context selector: #new.
	service currentContext: context.
	debugger session: session.

	references := debugger serverClassReferenceStrings.

	self assert: references equals: #('Invoice>>totalPrice')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSelectedServerMethodObjectBindsCurrentReceiverForInstanceMethods [
	| session context methodObject |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #totalPrice.
	service currentContext: context.
	service currentReceiverOop: 9001.
	debugger session: session.

	methodObject := debugger selectedServerMethodObject.

	self assert: methodObject notNil.
	self assert: methodObject isBound.
	self assert: methodObject selector equals: #totalPrice.
	self assert: methodObject receiver oop equals: 9001
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSelectedServerUnboundMethodObjectUsesUnboundMethodSurface [
	| session context methodObject |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #totalPrice.
	service currentContext: context.
	service currentReceiverOop: 9001.
	debugger session: session.

	methodObject := debugger selectedServerUnboundMethodObject.

	self assert: methodObject notNil.
	self deny: methodObject isBound.
	self assert: methodObject selector equals: #totalPrice.
	self assert: methodObject arity equals: 0
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testBrowseSelectedServerMethodInfoUsesUnboundMethodMetadata [
	| session context |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #totalPrice.
	service currentContext: context.
	debugger session: session.

	self assert: debugger browseSelectedServerMethodInfo.
	self assert: (debugger lastInfoMessage includesSubstring: 'Method: Invoice>>totalPrice').
	self assert: (debugger lastInfoMessage includesSubstring: 'Binding: unbound').
	self assert: (debugger lastInfoMessage includesSubstring: 'Arity: 0').
	self assert: (debugger lastInfoMessage includesSubstring: 'Protocol: pricing')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInvokeSelectedServerMethodObjectCallsBoundMethodObject [
	| session context capturedSelector capturedArguments capturedOop result |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #totalPrice.
	service currentContext: context.
	service currentReceiverOop: 9001.
	debugger session: session.

	result := debugger invokeSelectedServerMethodObject.

	self assert: result equals: #forwarded.
	self assert: capturedSelector equals: #totalPrice.
	self assert: capturedArguments equals: #().
	self assert: capturedOop equals: 9001
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInvokeSelectedServerMethodPromptsForArguments [
	| session context capturedSelector capturedArguments capturedOop |
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #applyDiscount:') ifTrue: [
			^ #(2002 'Invoice' 'applyDiscount:' 'pricing' 'applyDiscount: percent ^ total * percent' 'Billing-Core' 'Invoice>>applyDiscount:' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].
	context := GbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice'.
	context selector: #applyDiscount:.
	service currentContext: context.
	service currentReceiverOop: 9001.
	debugger session: session.
	debugger enqueueRequestAnswer: '15'.

	self assert: debugger invokeSelectedServerMethod.
	self assert: capturedSelector equals: #applyDiscount:.
	self assert: capturedArguments equals: #(15).
	self assert: capturedOop equals: 9001.
	self assert: (debugger lastInfoMessage includesSubstring: '#discounted')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testAcceptSourceEditsDelegatesRecompileWithCurrentText [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo ^ 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger acceptSourceEdits.
	self assert: service recompileCalls equals: 1.
	self assert: service lastRecompiledSource equals: 'foo ^ 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testAcceptSourceEditsShowsCompileErrorWhenRecompileFails [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo ^'.
	debugger instVarNamed: 'sourceText' put: fakeText.
	service
		recompileShouldSucceed: false;
		lastCompileError: 'Syntax error near ^'.

	self deny: debugger acceptSourceEdits.
	self assert: (fakeText text includesSubstring: 'Compile error: Syntax error near ^')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveBreakPointDelegatesToService [
	self assert: debugger removeBreakPoint.
	self assert: service removeBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveAllBreakPointsDelegatesToService [
	self assert: debugger removeAllBreakPoints equals: 1.
	self assert: service removeAllBreakPointsCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightSelectsIntervalOnSourceText [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	service sourceMap: { 1 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.
	context := GbxActivation new.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (2 to: 4).
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightUsesCurrentStepPointWhenSourceMapKeysAreStrings [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	service sourceMap: {
		'1' -> (1 to: 1).
		'4' -> (4 to: 4)
	}.
	debugger instVarNamed: 'sourceText' put: fakeText.
	context := GbxActivation new.
	context quickStepPoint: 4.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (4 to: 4).
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightFallsBackToDisplayedLineNumber [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'aa', String lf, 'bb', String lf, 'cc'.
	service sourceMap: #().
	debugger instVarNamed: 'sourceText' put: fakeText.

	context := GbxActivation new.
	context
		methodClass: 'nil';
		selector: #nil;
		ipOffset: 2;
		sourceString: ''.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (4 to: 5)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testContextSelectedFetchesFullSourceForSingleLineNilFrame [
	| mockSession fakeText fakeTable context rendered |
	mockSession := MockGbsSession new.
	mockSession stubs
		at: #evaluate
		put: ' | a b |<LF>a := 10.<LF>b := 0.<LF><LF>a / b'.

	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	context := GbxFakeContextForRemoteDebugger new
		methodClass: 'nil';
		sourceString: '| a b |';
		processOop: 222;
		level: 8;
		tempNamesAndValues: (Dictionary new
			at: 'a' put: '10';
			at: 'b' put: '0';
			yourself);
		yourself.

	debugger session: mockSession.
	debugger instVarNamed: 'sourceText' put: fakeText.
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	debugger contextSelected: context.

	rendered := fakeText text.
	self assert: (rendered includes: Character lf).
	self assert: (rendered includesSubstring: 'a / b').
	self assert: context sourceString equals: rendered.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testContextSelectedDoesNotRaiseWhenSourceAndVariableWidgetsAreMissing [
	| context |
	context := GbxFakeContextForRemoteDebugger new
		methodClass: 'nil';
		sourceString: '| a |';
		processOop: 222;
		level: 1;
		tempNamesAndValues: Dictionary new;
		yourself.

	self shouldnt: [ debugger contextSelected: context ] raise: Error
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testStepIntoDoesNotRaiseWhenServiceDoesNotImplementStepInto [
	self shouldnt: [ debugger stepInto ] raise: Error
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testStackReportStringIncludesAllContextPrintStrings [
	| ctx1 ctx2 report |
	ctx1 := Object new.
	ctx2 := Object new.
	debugger instVarNamed: 'contextList' put: { ctx1. ctx2 }.

	report := debugger stackReportString.

	self assert: (report includesSubstring: ctx1 printString).
	self assert: (report includesSubstring: ctx2 printString)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testToggleGlueHidingDelegatesToService [
	self assert: debugger toggleGlueHiding.
	self assert: service toggleGlueHidingCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testCorrectSelectorDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo: x ^ x + 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger correctSelector.
	self assert: service correctSelectorCalls equals: 1.
	self assert: service lastRecompiledSource equals: 'foo: x ^ x + 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRestartDelegatesToService [
	self assert: debugger restart.
	self assert: service restartCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRestartPromotesExecutedCodeFrameToTopAndSelectsSourceStart [
	| firstContext executedContext fakeList fakeText |
	firstContext := GbxFakeContextForRemoteDebugger new
		methodClass: 'SmallInteger';
		selector: #/;
		sourceString: 'a / b';
		processOop: 222;
		level: 1;
		tempNamesAndValues: Dictionary new;
		yourself.
	executedContext := GbxFakeContextForRemoteDebugger new
		methodClass: 'nil';
		selector: #nil;
		sourceString: '| a b |', String lf, 'a := 10.', String lf, 'b := 0.', String lf, 'a / b';
		processOop: 222;
		level: 8;
		tempNamesAndValues: Dictionary new;
		yourself.

	debugger instVarNamed: 'contextList' put: { firstContext. executedContext }.
	service contextList: { firstContext. executedContext }.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	debugger instVarNamed: 'stackList' put: fakeList.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'placeholder'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	debugger normalizeRestartSelectionAndPosition.

	self assert: ((debugger instVarNamed: 'contextList') first == firstContext).
	self assert: ((debugger instVarNamed: 'contextList') second == executedContext).
	self assert: fakeList selectedIndex equals: 2.
	self assert: service currentContext == executedContext.
	self assert: fakeText selectionInterval equals: (1 to: 1)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testMoveSourceCursorToStartSelectsFirstCharacter [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '1+1.', String lf, '1/0'.
	fakeText selectionInterval: (5 to: 5).
	debugger instVarNamed: 'sourceText' put: fakeText.

	debugger moveSourceCursorToStart.

	self assert: fakeText selectionInterval equals: (1 to: 1)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testPauseProcessDelegatesToService [
	self assert: debugger pauseProcess.
	self assert: service pauseCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testNormalizePauseLandingSelectionSelectsTopFrame [
	| top lower fakeList fakeText |
	top := GbxFakeContextForRemoteDebugger new
		methodClass: 'AbstractException';
		selector: #signal;
		sourceString: 'top source';
		processOop: 222;
		level: 1;
		tempNamesAndValues: Dictionary new;
		yourself.
	lower := GbxFakeContextForRemoteDebugger new
		methodClass: 'SmallInteger';
		selector: #/;
		sourceString: 'lower source';
		processOop: 222;
		level: 2;
		tempNamesAndValues: Dictionary new;
		yourself.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'placeholder'.

	debugger instVarNamed: 'contextList' put: { top. lower }.
	debugger instVarNamed: 'stackList' put: fakeList.
	debugger instVarNamed: 'sourceText' put: fakeText.

	debugger normalizePauseLandingSelection.

	self assert: fakeList selectedIndex equals: 1.
	self assert: service currentContext == top
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRunWithBreakAgainDelegatesToServiceCommand [
	self assert: debugger runWithBreakAgain.
	self assert: service runWithBreakAgainCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRunToCaretUsesSelectedStepPoint [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	service sourceMap: { 2 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger runToCaret.
	self assert: service runToStepPointCalls equals: 1.
	self assert: service lastStepPoint equals: 2
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRunToCaretUsesRemoteProcessFacadeWhenServiceMissing [
	| fakeText session context fakeList sawRun |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script includesSubstring: 'Object _objectForOop: 9001').
		(script includesSubstring: 'perform: #runToStepPoint: with: 2') ifTrue: [
			sawRun := true.
			^ 'true' ].
		(script includesSubstring: '_gsiStackReportFromLevel:') ifTrue: [
			^ '1', Character tab asString, 'DemoWorker', Character tab asString, 'run', Character tab asString, 'run', Character tab asString, '2', Character tab asString, '1,5,9', Character tab asString, '3', String lf ].
		(script includesSubstring: '(Reflection oopOf: proc) asString')
			ifTrue: [ ^ '9001' ].
		self fail ].
	session stubs at: #evaluate put: [ :script | '' ].
	context := GbxFakeContextForRemoteDebugger new
		level: 1;
		processOop: 9001;
		visibleSourceMap: { 2 -> (2 to: 4) };
		yourself.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	fakeList selectIndex: 1.
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'service' put: nil.
	debugger instVarNamed: 'sourceText' put: fakeText.
	debugger instVarNamed: 'contextList' put: { context }.
	debugger instVarNamed: 'stackList' put: fakeList.

	self assert: debugger runToCaret.
	self assert: sawRun
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testFetchContextsDirectlyUsesRemoteProcessFacadeContextActivations [
	| session contexts |
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script includesSubstring: 'Object _objectForOop: 9001').
		self assert: (script includesSubstring: '_gsiStackReportFromLevel:').
		^ '1', Character tab asString, 'DemoWorker', Character tab asString, 'run', Character tab asString, 'run', Character tab asString, '2', Character tab asString, '1,5,9', Character tab asString, '3', String lf ].
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'service' put: nil.

	contexts := debugger fetchContextsDirectly.

	self assert: contexts size equals: 1.
	self assert: contexts first processOop equals: 9001.
	self assert: contexts first methodClassOrUnknown equals: 'DemoWorker'.
	self assert: contexts first selectorOrUnknown equals: #run.
	self assert: contexts first quickStepPoint equals: 2.
	self assert: contexts first sourceOffsets equals: #(1 5 9).
	self assert: contexts first ipOffset equals: 3
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testJumpToCaretUsesSelectedStepPoint [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	service sourceMap: { 4 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger jumpToCaret.
	self assert: service jumpToStepPointCalls equals: 1.
	self assert: service lastStepPoint equals: 4
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testReturnFromFrameUsesServiceReturnWhenAvailable [
	self assert: debugger returnFromFrame.
	self assert: service returnFromFrameCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testReturnFromFrameUsesRemoteProcessFacadeWhenServiceMissing [
	| session fakeList sawStepReturn |
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script includesSubstring: 'Object _objectForOop: 9001').
		(script includesSubstring: 'perform: #stepReturn') ifTrue: [
			sawStepReturn := true.
			^ 'true' ].
		(script includesSubstring: '_gsiStackReportFromLevel:') ifTrue: [
			^ '1', Character tab asString, 'DemoWorker', Character tab asString, 'run', Character tab asString, 'run', Character tab asString, '2', Character tab asString, '1,5,9', Character tab asString, '3', String lf ].
		(script includesSubstring: '(Reflection oopOf: proc) asString')
			ifTrue: [ ^ '9001' ].
		self fail ].
	session stubs at: #evaluate put: [ :script | '' ].
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'service' put: nil.
	debugger instVarNamed: 'stackList' put: fakeList.

	self assert: debugger returnFromFrame.
	self assert: sawStepReturn
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testResolveDebugProcessOopFromCurrentProcessOopUsesRemoteProcessFacade [
	| session sawResolve |
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		sawResolve := true.
		'9501' ].
	debugger
		session: session;
		processOop: 9001.

	self assert: debugger resolveDebugProcessOopFromCurrentProcessOop equals: 9501.
	self assert: sawResolve
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testResolveDebugProcessOopFallsBackToNilContextWhenSessionOopIsImmediate [
	| session sawResolve |
	session := MockGbsSession new.
	session sessionOop: 1.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		(script includesSubstring: '(Reflection oopOf: proc) asString')
			ifTrue: [ sawResolve := true ].
		^ '9501' ].
	debugger
		session: session;
		processOop: 9001.

	self assert: debugger resolveDebugProcessOopFromCurrentProcessOop equals: 9501.
	self assert: sawResolve
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testForceServerJumpToStepPoint1UsesRemoteProcessFacade [
	| session sawStackReport sawStepReset |
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		(script includesSubstring: 'WriteStream on: String new')
			ifTrue: [
				sawStackReport := true.
				^ '3', Character tab asString, 'nil', Character tab asString, 'nil', String lf ].
		(script includesSubstring: '_gsiStepAtLevel:step:')
			ifTrue: [
				sawStepReset := true.
				self assert: (script includesSubstring: 'Object _objectForOop: 9001').
				self assert: (script includesSubstring: '_trimStackToLevel: restartLevel').
				self assert: (script includesSubstring: '_gsiStepAtLevel: restartLevel step: 1').
				^ 'true' ].
		^ 'true' ].
	debugger
		session: session;
		processOop: 9001.

	self assert: debugger forceServerJumpToStepPoint1.
	self assert: sawStackReport.
	self assert: sawStepReset
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRestartUsingDirectTrimFromExecutedFrameUsesRemoteProcessFacade [
	| session context sawTrim |
	session := MockGbsSession new.
	context := GbxFakeContextForRemoteDebugger new
		processOop: 9001;
		level: 3;
		yourself.
	service currentContext: context.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		(script includesSubstring: '_trimStackToLevel:')
			ifTrue: [
				sawTrim := true.
				self assert: (script includesSubstring: 'Object _objectForOop: 9001').
				self assert: (script includesSubstring: '_trimStackToLevel:').
				self assert: (script includesSubstring: 'restartLevel :=') ].
		^ 'true' ].
	debugger
		session: session;
		processOop: 9001.

	self assert: debugger restartUsingDirectTrimFromExecutedFrame.
	self assert: sawTrim
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testDirectStepWithPrimarySelectorUsesRemoteProcessFacade [
	| session context fakeList |
	session := MockGbsSession new.
	context := GbxFakeContextForRemoteDebugger new
		level: 4;
		yourself.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	fakeList selectIndex: 1.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script includesSubstring: 'Object _objectForOop: 9001').
		self assert: (script includesSubstring: 'selector := #_stepIntoInFrame:').
		self assert: (script includesSubstring: 'proc perform: selector with: level').
		self assert: (script includesSubstring: 'proc perform: #_step: with: level').
		^ 'true' ].
	debugger session: session.
	debugger instVarNamed: 'processOop' put: 9001.
	debugger instVarNamed: 'service' put: nil.
	debugger instVarNamed: 'contextList' put: { context }.
	debugger instVarNamed: 'stackList' put: fakeList.

	self assert: (debugger
		directStepWithPrimarySelector: '_stepIntoInFrame:'
		fallbackSelector: '_step:')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testDirectStepOverExecutedFrameUsesRemoteProcessFacade [
	| session context fakeList sawStep |
	session := MockGbsSession new.
	context := GbxFakeContextForRemoteDebugger new
		level: 2;
		yourself.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	fakeList selectIndex: 1.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		(script includesSubstring: 'WriteStream on: String new')
			ifTrue: [ ^ '2', Character tab asString, 'nil', Character tab asString, 'unboundMethod', String lf ].
		(script includesSubstring: '_gsiStepAtLevel: restartLevel step: 1')
			ifTrue: [ ^ 'true' ].
		(script includesSubstring: 'selector := #_stepOverInFrame:')
			ifTrue: [
				sawStep := true.
				self assert: (script includesSubstring: 'level := 4294967298').
				^ 'true' ].
		self fail ].
	debugger session: session.
	debugger instVarNamed: 'processOop' put: 9001.
	debugger instVarNamed: 'service' put: nil.
	debugger instVarNamed: 'contextList' put: { context }.
	debugger instVarNamed: 'stackList' put: fakeList.

	self assert: (debugger directStepOverExecutedFrame: true).
	self assert: sawStep
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testFetchFullSourceForUsesRemoteProcessFacade [
	| session context source |
	session := MockGbsSession new.
	context := GbxFakeContextForRemoteDebugger new
		processOop: 9001;
		level: 2;
		yourself.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script includesSubstring: 'Object _objectForOop: 9001').
		self assert: (script includesSubstring: '_gsiStackReportFromLevel: 2 toLevel: 2').
		self assert: (script includesSubstring: 'proc topContext').
		^ 'line1<TAB>value<LF>line2<CR>value' ].
	debugger session: session.

	source := debugger fetchFullSourceFor: context.

	self assert: source equals: 'line1', Character tab asString, 'value', String lf, 'line2', String cr, 'value'
]
