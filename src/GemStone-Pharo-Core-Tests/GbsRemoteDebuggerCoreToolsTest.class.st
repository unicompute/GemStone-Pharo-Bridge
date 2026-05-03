Class {
	#name : 'GbsRemoteDebuggerCoreToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'debugger',
		'service'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerCoreToolsTest >> setUp [
	super setUp.
	debugger := CoreTestableGbsRemoteDebugger new.
	service := CoreGbxFakeServiceForRemoteDebugger new.
	debugger service: service.
]

{ #category : 'private' }
GbsRemoteDebuggerCoreToolsTest >> requireRemoteDebuggerSelector: aSelector [
	(debugger class canUnderstand: aSelector) ifFalse: [
		self skip: 'Requires GemStone-GBS-MagLev debugger extensions.' ]
]

{ #category : 'private' }
GbsRemoteDebuggerCoreToolsTest >> restartExecutedActivationForProcess: processOop stepPoint: stepPoint source: sourceText [
	| activation |
	activation := GbxActivation new.
	activation
		processOop: processOop;
		level: 1;
		methodClass: 'nil';
		selector: #unboundMethod;
		sourceString: sourceText;
		sourceOffsets: #(1 6);
		quickStepPoint: stepPoint;
		ipOffset: 1.
	^ activation
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| session |
	session := CoreMockGbsSession new.
	debugger session: session.
	debugger enqueueRequestAnswer: 'abc'.

	self deny: debugger browsePromptedSessionStateKey.
	self assert: debugger lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: debugger lastInspectedOop isNil
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| session |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesStaleEntries [
	| session stale current |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsReport [
	| session |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsReport [
	| session |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testServerMethodReferencesForImplementorsUsesSessionFacadeOutsideHierarchy [
	| session references |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testServerMethodReferencesForSendersUsesSessionFacadeOutsideHierarchy [
	| session references |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testServerMethodReferencesForHierarchyImplementorsUsesSessionFacade [
	| session references context |
	session := CoreMockGbsSession new.
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
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testServerMethodReferencesForHierarchySendersUsesSessionFacade [
	| session references context |
	session := CoreMockGbsSession new.
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
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testSelectedServerReferenceTargetNameStripsClassSideSuffix [
	| context |
	context := CoreGbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice class'.
	context selector: #new.
	service currentContext: context.

	self assert: debugger selectedServerReferenceTargetName equals: 'Invoice'
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testServerClassReferenceStringsUsesSessionFacade [
	| session references context |
	session := CoreMockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Class reference queries should use the repository facade.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'organizer referencesTo: #Invoice').
			^ #('Invoice>>totalPrice') ].
	context := CoreGbxFakeContextForRemoteDebugger new.
	context methodClass: 'Invoice class'.
	context selector: #new.
	service currentContext: context.
	debugger session: session.

	references := debugger serverClassReferenceStrings.

	self assert: references equals: #('Invoice>>totalPrice')
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyLoadPathReport.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyLoadedFeaturesReport.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyPersistentLoadedFeaturesReport.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| session |
	self requireRemoteDebuggerSelector: #browseTopLevelAutoloadRegistrationsReport.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyRuntimeProvenanceGraphUsesRuntimeReport [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyRuntimeProvenanceGraph.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyRuntimeProvenanceBrowserOpensStructuredGraph [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyRuntimeProvenanceBrowser.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseRubyRuntimeProvenanceActionChooserExecutesSelectedAction [
	| session |
	self requireRemoteDebuggerSelector: #browseRubyRuntimeProvenanceActionChooser.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsReport [
	| session |
	self requireRemoteDebuggerSelector: #browseMaglevFinalizerRegistryReport.
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testSelectedServerMethodObjectBindsCurrentReceiverForInstanceMethods [
	| session context methodObject |
	self requireRemoteDebuggerSelector: #selectedServerMethodObject.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testSelectedServerUnboundMethodObjectUsesUnboundMethodSurface [
	| session context methodObject |
	self requireRemoteDebuggerSelector: #selectedServerUnboundMethodObject.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testBrowseSelectedServerMethodInfoUsesUnboundMethodMetadata [
	| session context |
	self requireRemoteDebuggerSelector: #browseSelectedServerMethodInfo.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testInvokeSelectedServerMethodObjectCallsBoundMethodObject [
	| session context capturedSelector capturedArguments capturedOop result |
	self requireRemoteDebuggerSelector: #invokeSelectedServerMethodObject.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testInvokeSelectedServerMethodPromptsForArguments [
	| session context capturedSelector capturedArguments capturedOop |
	self requireRemoteDebuggerSelector: #invokeSelectedServerMethodObject.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #applyDiscount:') ifTrue: [
			^ #(2002 'Invoice' 'applyDiscount:' 'pricing' 'applyDiscount: percent ^ total * percent' 'Billing-Core' 'Invoice>>applyDiscount:' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].
	context := CoreGbxFakeContextForRemoteDebugger new.
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
GbsRemoteDebuggerCoreToolsTest >> testRunToCaretUsesRemoteProcessFacadeWhenServiceMissing [
	| fakeText session context fakeList sawRun |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	session := CoreMockGbsSession new.
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
	context := CoreGbxFakeContextForRemoteDebugger new
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
GbsRemoteDebuggerCoreToolsTest >> testFetchContextsDirectlyUsesRemoteProcessFacadeContextActivations [
	| session contexts |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testReturnFromFrameUsesRemoteProcessFacadeWhenServiceMissing [
	| session fakeList sawStepReturn |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testResolveDebugProcessOopFromCurrentProcessOopUsesRemoteProcessFacade [
	| session sawResolve |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testResolveDebugProcessOopFallsBackToNilContextWhenSessionOopIsImmediate [
	| session sawResolve |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testForceServerJumpToStepPoint1UsesRemoteProcessFacade [
	| session sawStackReport sawStepReset |
	session := CoreMockGbsSession new.
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
GbsRemoteDebuggerCoreToolsTest >> testRestartUsingDirectTrimFromExecutedFrameUsesRemoteProcessFacade [
	| session context sawTrim |
	session := CoreMockGbsSession new.
	context := CoreGbxFakeContextForRemoteDebugger new
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
GbsRemoteDebuggerCoreToolsTest >> testRestartUsesFreshFaultedProcessWhenExecutedFrameNeedsServerRewind [
	| session source oldContext staleExecutedContext restartedContext stackList sourceText executedScripts restartCalls |
	session := CoreMockGbsSession new.
	source := '1+1.', String lf, '1/0'.
	executedScripts := OrderedCollection new.
	restartCalls := 0.
	oldContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 2
		source: source.
	staleExecutedContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 2
		source: source.
	restartedContext := self
		restartExecutedActivationForProcess: 9501
		stepPoint: 1
		source: source.
	service currentContext: oldContext.
	service contextList: { oldContext }.
	service onRestartDo: [ :fakeService |
		restartCalls := restartCalls + 1.
		restartCalls = 1
			ifTrue: [
				fakeService contextList: { staleExecutedContext }.
				fakeService currentContext: staleExecutedContext ]
			ifFalse: [
				fakeService contextList: { restartedContext }.
				fakeService currentContext: restartedContext ]
	].
	session stubs
		at: #execute
		put: [ :script |
			executedScripts add: script.
			(GbsError new
				messageText: 'boom';
				serverProcessOop: 9501;
				yourself) signal ].
	stackList := GbxFakeListPresenterForRemoteDebugger new.
	stackList selectIndex: 1.
	sourceText := GbxFakeTextPresenterForRemoteDebugger new.
	sourceText
		text: source;
		selectionInterval: (1 to: 1).
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'stackList' put: stackList.
	debugger instVarNamed: 'sourceText' put: sourceText.
	debugger instVarNamed: 'contextList' put: { oldContext }.

	self assert: debugger restart.
	self assert: restartCalls equals: 2.
	self assert: executedScripts asArray equals: { source }.
	self assert: debugger processOop equals: 9501.
	self assert: service processOop equals: 9501.
	self assert: service terminateCalls equals: 1.
	self assert: service initializeForDebuggingCalls equals: 1.
	self assert: service restartCalls equals: 2.
	self assert: service resetServerPCToStepOneCalls >= 1.
	self assert: service currentContext printString equals: 'GS: Executed code @1 line 1'.
	self assert: (debugger instVarNamed: 'contextList') first printString equals: 'GS: Executed code @1 line 1'.
	self assert: stackList selectedIndex equals: 1.
	self assert: sourceText text equals: source
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testRestartUsesFreshFaultedProcessWhenSelectedFrameIsNotExecutedCode [
	| session source selectedContext staleExecutedContext restartedContext stackList sourceText executedScripts restartCalls |
	session := CoreMockGbsSession new.
	source := '1+1.', String lf, '1/0'.
	executedScripts := OrderedCollection new.
	restartCalls := 0.
	selectedContext := GbxActivation new.
	selectedContext
		processOop: 9001;
		level: 1;
		methodClass: 'SmallInteger';
		selector: #/;
		sourceString: source;
		sourceOffsets: #(1 6);
		quickStepPoint: 1;
		ipOffset: 1.
	staleExecutedContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 2
		source: source.
	restartedContext := self
		restartExecutedActivationForProcess: 9501
		stepPoint: 1
		source: source.
	service currentContext: selectedContext.
	service contextList: { selectedContext. staleExecutedContext }.
	service onRestartDo: [ :fakeService |
		restartCalls := restartCalls + 1.
		restartCalls = 1
			ifTrue: [
				fakeService contextList: { selectedContext. staleExecutedContext }.
				fakeService currentContext: selectedContext ]
			ifFalse: [
				fakeService contextList: { restartedContext }.
				fakeService currentContext: restartedContext ] ].
	session stubs
		at: #execute
		put: [ :script |
			executedScripts add: script.
			(GbsError new
				messageText: 'boom';
				serverProcessOop: 9501;
				yourself) signal ].
	stackList := GbxFakeListPresenterForRemoteDebugger new.
	stackList selectIndex: 1.
	sourceText := GbxFakeTextPresenterForRemoteDebugger new.
	sourceText
		text: source;
		selectionInterval: (1 to: 1).
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'stackList' put: stackList.
	debugger instVarNamed: 'sourceText' put: sourceText.
	debugger instVarNamed: 'contextList' put: { selectedContext. staleExecutedContext }.

	self assert: debugger restart.
	self assert: restartCalls equals: 2.
	self assert: executedScripts asArray equals: { source }.
	self assert: debugger processOop equals: 9501.
	self assert: service currentContext printString equals: 'GS: Executed code @1 line 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testRestartUsesFreshFaultedProcessWhenServiceSignalsReplayEvenThoughDisplayedStepIsOne [
	| session source oldContext displayedStepOneContext restartedContext stackList sourceText executedScripts restartCalls |
	session := CoreMockGbsSession new.
	source := '1+1.', String lf, '1/0'.
	executedScripts := OrderedCollection new.
	restartCalls := 0.
	oldContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 3
		source: source.
	displayedStepOneContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 1
		source: source.
	restartedContext := self
		restartExecutedActivationForProcess: 9501
		stepPoint: 1
		source: source.
	service currentContext: oldContext.
	service contextList: { oldContext }.
	service onRestartDo: [ :fakeService |
		restartCalls := restartCalls + 1.
		restartCalls = 1
			ifTrue: [
				fakeService contextList: { displayedStepOneContext }.
				fakeService currentContext: displayedStepOneContext.
				fakeService restartNeedsFreshFaultReplay: true ]
			ifFalse: [
				fakeService contextList: { restartedContext }.
				fakeService currentContext: restartedContext.
				fakeService restartNeedsFreshFaultReplay: false ] ].
	session stubs
		at: #execute
		put: [ :script |
			executedScripts add: script.
			(GbsError new
				messageText: 'boom';
				serverProcessOop: 9501;
				yourself) signal ].
	stackList := GbxFakeListPresenterForRemoteDebugger new.
	stackList selectIndex: 1.
	sourceText := GbxFakeTextPresenterForRemoteDebugger new.
	sourceText
		text: source;
		selectionInterval: (1 to: 1).
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'stackList' put: stackList.
	debugger instVarNamed: 'sourceText' put: sourceText.
	debugger instVarNamed: 'contextList' put: { oldContext }.

	self assert: debugger restart.
	self assert: restartCalls equals: 2.
	self assert: executedScripts asArray equals: { source }.
	self assert: debugger processOop equals: 9501.
	self assert: service currentContext printString equals: 'GS: Executed code @1 line 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testRestartUsesExecutedSourceInsteadOfSelectedWidgetTextForReplay [
	| session source oldContext displayedStepOneContext restartedContext stackList sourceText executedScripts |
	session := CoreMockGbsSession new.
	source := '1+1.', String lf, '1/0'.
	executedScripts := OrderedCollection new.
	oldContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 3
		source: source.
	displayedStepOneContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 1
		source: source.
	restartedContext := self
		restartExecutedActivationForProcess: 9501
		stepPoint: 1
		source: source.
	service currentContext: oldContext.
	service contextList: { oldContext }.
	service onRestartDo: [ :fakeService |
		(fakeService restartCalls = 1)
			ifTrue: [
				fakeService contextList: { displayedStepOneContext }.
				fakeService currentContext: displayedStepOneContext.
				fakeService restartNeedsFreshFaultReplay: true ]
			ifFalse: [
				fakeService contextList: { restartedContext }.
				fakeService currentContext: restartedContext.
				fakeService restartNeedsFreshFaultReplay: false ] ].
	session stubs
		at: #execute
		put: [ :script |
			executedScripts add: script.
			(GbsError new
				messageText: 'boom';
				serverProcessOop: 9501;
				yourself) signal ].
	stackList := GbxFakeListPresenterForRemoteDebugger new.
	stackList selectIndex: 1.
	sourceText := GbxFakeTextPresenterForRemoteDebugger new.
	sourceText
		text: source;
		selectedText: '1+1.';
		selectionInterval: (1 to: 4).
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'stackList' put: stackList.
	debugger instVarNamed: 'sourceText' put: sourceText.
	debugger instVarNamed: 'contextList' put: { oldContext }.

	self assert: debugger restart.
	self assert: executedScripts asArray equals: { source }.
	self assert: debugger processOop equals: 9501
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testRestartWithFreshFaultedProcessReturnsFalseWhenErrorHasNoProcessOop [
	| session source oldContext staleExecutedContext stackList sourceText |
	session := CoreMockGbsSession new.
	source := '1+1.', String lf, '1/0'.
	oldContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 2
		source: source.
	staleExecutedContext := self
		restartExecutedActivationForProcess: 9001
		stepPoint: 2
		source: source.
	service currentContext: oldContext.
	service contextList: { oldContext }.
	service onRestartDo: [ :fakeService |
		fakeService contextList: { staleExecutedContext }.
		fakeService currentContext: staleExecutedContext ].
	session stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'boom';
				yourself) signal ].
	stackList := GbxFakeListPresenterForRemoteDebugger new.
	stackList selectIndex: 1.
	sourceText := GbxFakeTextPresenterForRemoteDebugger new.
	sourceText
		text: source;
		selectionInterval: (1 to: 1).
	debugger
		session: session;
		processOop: 9001.
	debugger instVarNamed: 'stackList' put: stackList.
	debugger instVarNamed: 'sourceText' put: sourceText.
	debugger instVarNamed: 'contextList' put: { oldContext }.

	self deny: debugger restart.
	self assert: debugger processOop equals: 9001.
	self assert: service processOop isNil.
	self assert: service terminateCalls equals: 0.
	self assert: service restartCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerCoreToolsTest >> testDirectStepWithPrimarySelectorUsesRemoteProcessFacade [
	| session context fakeList |
	session := CoreMockGbsSession new.
	context := CoreGbxFakeContextForRemoteDebugger new
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
GbsRemoteDebuggerCoreToolsTest >> testDirectStepOverExecutedFrameUsesRemoteProcessFacade [
	| session context fakeList sawStep |
	session := CoreMockGbsSession new.
	context := CoreGbxFakeContextForRemoteDebugger new
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
GbsRemoteDebuggerCoreToolsTest >> testFetchFullSourceForUsesRemoteProcessFacade [
	| session context source |
	session := CoreMockGbsSession new.
	context := CoreGbxFakeContextForRemoteDebugger new
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
