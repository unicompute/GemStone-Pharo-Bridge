Class {
	#name : 'GbsSessionMagLevTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'tests' }
GbsSessionMagLevTest >> testSessionMethodsAccessorUsesSymbolDictionaryFacade [
	| mockSession result |
	mockSession := CoreMockGbsSession new.

	result := mockSession sessionMethods.

	self assert: result class equals: GbsSymbolDictionaryFacade.
	self assert: result name equals: 'SessionMethods'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testMaglevFacadeExposesBridgeRootAndSharedCounters [
	| mockSession maglev sharedCounter |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'System transactionLevel' ifTrue: [ ^ 2 ].
		script = 'System sharedCounter: 3' ifTrue: [ ^ 41 ].
		script = 'System sharedCounter: 3 incrementBy: 2' ifTrue: [ ^ 43 ].
		self fail ].

	maglev := mockSession maglev.
	sharedCounter := maglev sharedCounterAt: 3.

	self assert: maglev bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: maglev transactionLevel equals: 2.
	self assert: sharedCounter value equals: 41.
	self assert: (sharedCounter incrementBy: 2) equals: 43
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testMaglevBridgeRootMaterializesRcAndProcEntries [
	| mockSession root counter proc |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'clsName :=') ifTrue: [ ^ #('Proc' 1 false nil nil nil #() #() #()) ].
		(script includesSubstring: '#counter') ifTrue: [ ^ GbsProxy oop: 7001 session: mockSession ].
		(script includesSubstring: '#job') ifTrue: [ ^ GbsProxy oop: 7002 session: mockSession ].
		(script includesSubstring: '#missing') ifTrue: [ ^ nil ].
		self fail ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7001') ifTrue: [ ^ 'RcCounter' ].
		(script includesSubstring: '7002') ifTrue: [ ^ 'Proc' ].
		self fail ].

	root := mockSession maglev bridgeRoot.
	counter := root at: #counter.
	proc := root at: #job.

	self assert: counter class equals: GbsRcCounter.
	self assert: proc class equals: GbsRemoteProcObject.
	self assert: (root at: #missing ifAbsent: [ #fallback ]) equals: #fallback
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectSpaceDiagnosticsFacadeReportTextSummarizesWellKnownSessionState [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].

	report := mockSession objectSpaceDiagnostics reportText.

	self assert: (report includesSubstring: 'Session State').
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectSpaceDiagnosticsFacadeSupportsNamedSlotAliases [
	| mockSession diagnostics slot report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotNamed: 'maglev_finalizer_registry'.
	report := diagnostics reportTextForSlotNames: #('ruby finalizers').

	self assert: (diagnostics slotKeyNamed: 'maglev_finalizer_registry') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'ruby finalizers') equals: 19.
	self assert: slot key equals: 19.
	self assert: slot label equals: 'MagLev Finalizer Registry'.
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectLogFacadeMapsEntriesAndMaterializesPayloads [
	| mockSession entries entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry objectLog') ifTrue: [
			^ { { 1. 4. 'Saved object'. 1234. '2026-01-01T10:00:00Z'. 'runtime'. true. 7101. 'a counter' } } ].
		self fail ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7101') ifTrue: [ ^ 'RcCounter' ].
		self fail ].

	entries := mockSession objectLog entries.
	entry := entries first.

	self assert: entries size equals: 1.
	self assert: entry priorityLabel equals: 'INFO'.
	self assert: entry label equals: 'Saved object'.
	self assert: entry object class equals: GbsRcCounter.
	self assert: (mockSession objectLog reportText includesSubstring: 'Saved object')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testMaglevFacadeExposesSymbolDictionaryFacades [
	| mockSession maglev |
	mockSession := CoreMockGbsSession new.
	maglev := mockSession maglev.

	self assert: maglev globals class equals: GbsSymbolDictionaryFacade.
	self assert: maglev globals name equals: 'Globals'.
	self assert: maglev published class equals: GbsSymbolDictionaryFacade.
	self assert: maglev published name equals: 'Published'.
	self assert: maglev userGlobals class equals: GbsSymbolDictionaryFacade.
	self assert: maglev userGlobals name equals: 'UserGlobals'.
	self assert: maglev sessionMethods class equals: GbsSymbolDictionaryFacade.
	self assert: maglev sessionMethods name equals: 'SessionMethods'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testMaterializeMaglevRuntimeValueMapsGsDictionaryAndGenericObject [
	| mockSession dictionary object |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7201') ifTrue: [ ^ 'StringKeyValueDictionary' ].
		(script includesSubstring: '7202') ifTrue: [ ^ 'RubyServiceThing' ].
		self fail ].

	dictionary := mockSession materializeMaglevRuntimeValue: (GbsProxy oop: 7201 session: mockSession).
	object := mockSession materializeMaglevRuntimeValue: (GbsProxy oop: 7202 session: mockSession).

	self assert: dictionary class equals: GbsGsDictionary.
	self assert: object class equals: GbsGsObject.
	self assert: object oop equals: 7202
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectLogFacadeWritesTaggedEntriesAndCommits [
	| mockSession commitCount |
	mockSession := CoreMockGbsSession new.
	commitCount := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry info:') ifTrue: [
			self assert: (script includesSubstring: '''Tagged entry''').
			self assert: (script includesSubstring: 'entry tag:').
			self assert: (script includesSubstring: '''runtime''').
			^ true ].
		self fail ].
	mockSession stubs at: #gciCommit put: [
		commitCount := commitCount + 1.
		1 ].

	self assert: (mockSession objectLog info: 'Tagged entry' object: nil tag: 'runtime').
	self assert: commitCount equals: 1
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorsBuildExpectedMetadataAndConstants [
	| mockSession mirrors first topLevel constants autoloads |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(
				#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)
				#(2 5002 'Globals' nil 'SymbolDictionary' nil)) ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: 'rubyAutoloadFileFor:')
					ifTrue: [ ^ 'lib/lazy_thing.rb' ].
				(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
					ifTrue: [ ^ #(
						#('LazyThing' 'lib/lazy_thing.rb' nil 9101)) ].
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('Invoice' 1001 'Class' nil 'Invoice' 'Accounting::Invoice')
						#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ].
				^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	mirrors := mockSession namespaceMirrors.
	first := mirrors first.
	topLevel := mockSession topLevelNamespaceMirror.
	constants := topLevel constantMirrors.
	autoloads := topLevel autoloadMirrors.

	self assert: mirrors size equals: 2.
	self assert: first class equals: GbsRemoteNamespaceMirror.
	self assert: first index equals: 1.
	self assert: first name equals: 'UserGlobals'.
	self assert: first displayName equals: 'UserGlobals'.
	self assert: first className equals: 'SymbolDictionary'.
	self assert: first oop equals: 5001.
	self assert: first proxy oop equals: 5001.
	self assert: topLevel exists.
	self assert: topLevel moduleName equals: 'Object'.
	self assert: topLevel displayName equals: 'Object'.
	self assert: constants size equals: 2.
	self assert: autoloads size equals: 1.
	self assert: constants first name equals: 'Invoice'.
	self assert: constants first valueName equals: 'Invoice'.
	self assert: constants first valueFullName equals: 'Accounting::Invoice'.
	self assert: constants first browsableName equals: 'Accounting::Invoice'.
	self deny: constants first isAutoload.
	self assert: autoloads first class equals: GbsRemoteAutoloadMirror.
	self assert: autoloads first name equals: 'LazyThing'.
	self assert: autoloads first autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: autoloads first rawState isNil.
	self assert: autoloads first oop equals: 9101.
	self assert: autoloads first proxy oop equals: 9101.
	self assert: autoloads first stateLabel equals: 'Loading'.
	self assert: constants second isAutoload.
	self assert: constants second autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: constants second browsableName equals: 'LazyThing'.
	self assert: (topLevel autoloadFileFor: #LazyThing) equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorRegisterAutoloadBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoload: name asSymbol file: file')
			ifTrue: [
				self assert: (script includesSubstring: 'Object nameSpace: 1').
				self assert: (script includesSubstring: '''LazyThing''').
				self assert: (script includesSubstring: '''lib/lazy_thing.rb''').
				^ 'lib/lazy_thing.rb' ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	namespace := mockSession topLevelNamespaceMirror.
	result := namespace
		registerAutoload: #LazyThing
		file: 'lib/lazy_thing.rb'.

	self assert: result equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorForObjectBuildsExactObjectExpression [
	| mockSession proxy namespace |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '[:value | value] value:').
		self assert: (script includesSubstring: '_objectForOop: 7101').
		self deny: (script includesSubstring: 'nameSpace: 1').
		^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
	proxy := GbsProxy oop: 7101 session: mockSession.

	namespace := mockSession namespaceMirrorForObject: proxy.

	self assert: namespace oop equals: 8001.
	self assert: namespace displayName equals: 'Accounting'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorParentNamespaceUsesContainingNamespaceExpression [
	| mockSession namespace parent |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '[:value | value] value:')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: 'cls ifNil: [ nil ] ifNotNil: [ cls nameSpace: 1 ]')
			ifTrue: [
				self assert: (script includesSubstring: '_objectForOop: 8101').
				^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		self fail ].
	namespace := mockSession namespaceMirrorForObject: (GbsProxy oop: 8101 session: mockSession).

	parent := namespace parentNamespaceMirror.

	self assert: parent notNil.
	self assert: parent oop equals: 8001.
	self assert: parent displayName equals: 'Accounting'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorForFullNameBuildsPathLookupExpression [
	| mockSession namespace |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'findTokens: ''::''').
		self assert: (script includesSubstring: 'current := Object nameSpace: 1').
		self assert: (script includesSubstring: '''Accounting::Invoice''').
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].

	namespace := mockSession namespaceMirrorForFullName: 'Accounting::Invoice'.

	self assert: namespace oop equals: 8101.
	self assert: namespace displayName equals: 'Accounting::Invoice'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorRemoveAutoloadBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1')
			ifTrue: [
				self assert: (script includesSubstring: 'removeConst: name asSymbol env: 1').
				self assert: (script includesSubstring: 'Object nameSpace: 1').
				self assert: (script includesSubstring: '''LazyThing''').
				^ true ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	namespace := mockSession topLevelNamespaceMirror.
	result := namespace removeAutoload: #LazyThing.

	self assert: result equals: true
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyLoadRequireAndLoadedFeaturesBuildExpectedScripts [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		script = 'RubyContext clear_persistent_LOADED_FEATURES' ifTrue: [ ^ true ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''foo'' env: 1')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'RubyContext default loadFileNamed: ''bar.rb'' env: 1')
			ifTrue: [ ^ 'loaded' ].
		self fail ].

	self assert: mockSession rubyLoadPath equals: #('lib' 'app/models').
	self assert: mockSession rubyLoadedFeatures equals: #('foo.rb').
	self assert: mockSession rubyPersistentLoadedFeatures equals: #('persisted.rb').
	self assert: (mockSession rubyRequireFileNamed: 'foo') equals: true.
	self assert: (mockSession rubyLoadFileNamed: 'bar.rb') equals: 'loaded'.
	self assert: mockSession clearPersistentRubyLoadedFeatures equals: true
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeFacadeReportIncludesAutoloadRegistrationsAndSessionStateSummary [
	| mockSession namespace report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	report := String streamContents: [ :stream |
		mockSession rubyRuntime
			appendRuntimeReportOn: stream
			namespace: namespace
			selectedConstant: nil
			selectedAutoload: nil ].

	self assert: (report includesSubstring: 'Autoload Registrations').
	self assert: (report includesSubstring: 'LazyThing -> lib/lazy_thing.rb [Pending]').
	self assert: (report includesSubstring: '$LOAD_PATH').
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeFacadeReportObjectExposesStructuredEntries [
	| mockSession namespace report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	report := mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil.

	self assert: report loadPathEntries size equals: 2.
	self assert: report loadedFeatureEntries size equals: 1.
	self assert: report persistentLoadedFeatureEntries size equals: 1.
	self assert: report autoloadRegistrations size equals: 1.
	self assert: report sessionStateSlots size equals: 1.
	self assert: report loadPathEntries first class equals: GbsRubyLoadPathEntry.
	self assert: report loadedFeatureEntries first class equals: GbsRubyLoadedFeatureEntry.
	self assert: report persistentLoadedFeatureEntries first isPersistent.
	self assert: report sessionStateSlots first class equals: GbsFinalizerRegistrySessionStateSlot.
	self assert: report sections size equals: 5.
	self assert: report sections first title equals: 'Autoload Registrations'.
	self assert: (report text includesSubstring: 'Ruby Runtime')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeFacadeAutoloadRegistrationEntriesExposeLifecycleMetadata [
	| mockSession namespace entries entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)) ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	entries := mockSession rubyRuntime autoloadRegistrationEntriesForNamespace: namespace.
	entry := entries first.

	self assert: entries size equals: 1.
	self assert: entry autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: entry persistentAutoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: entry isTransientCached.
	self assert: entry hasPersistentRegistration.
	self assert: entry registrationStateLabel equals: 'Transient+Persistent'.
	self assert: (entry displayString includesSubstring: '{Transient+Persistent}')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeEntriesExposeFileProvenanceMetadata [
	| loadPathEntry featureEntry autoloadEntry autoload |
	loadPathEntry := GbsRubyLoadPathEntry path: '/opt/demo/lib'.
	featureEntry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb' persistent: true.
	autoload := GbsRemoteAutoloadMirror
		on: (GbsRemoteNamespaceMirror topLevelOn: CoreMockGbsSession new)
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).
	autoloadEntry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: loadPathEntry provenanceLabel equals: 'Absolute Load Path'.
	self assert: loadPathEntry rootComponent equals: 'opt'.
	self assert: loadPathEntry pathComponents equals: #('opt' 'demo' 'lib').
	self assert: featureEntry provenanceLabel equals: 'Persistent Feature'.
	self assert: featureEntry isRubySource.
	self assert: featureEntry rootComponent equals: 'app'.
	self assert: autoloadEntry autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: autoloadEntry recoveryStateLabel equals: 'Recoverable'.
	self assert: autoloadEntry provenanceLabel equals: 'Transient+Persistent'.
	self assert: autoloadEntry isRubySource.
	self assert: autoloadEntry pathComponents equals: #('lib' 'lazy_thing.rb')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadMirrorRecoverRegistrationUsesPersistentFallback [
	| mockSession namespace autoload result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1') ifFalse: [ self fail ].
		self assert: (script includesSubstring: 'persistCopy').
		self assert: (script includesSubstring: 'rubyAutoload: name asSymbol file: fileName').
		^ 'lib/lazy_thing.rb' ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'autoloadEntries' put: #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).

	result := autoload recoverRegistration.

	self assert: result equals: 'lib/lazy_thing.rb'.
	self assert: (namespace instVarNamed: 'autoloadEntries') isNil
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteNamespaceMirrorScopedSelectorQueryFiltersGlobalResultsByNamespace [
	| mockSession namespace implementors senders references query |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'implementorsOf:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		(script includesSubstring: 'selectorsReferTo:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		(script includesSubstring: 'referencesTo:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: nil'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').

	implementors := namespace implementorMethodReferenceStringsForSelector: #size.
	senders := namespace senderMethodReferenceStringsForSelector: #size.
	references := namespace methodReferenceStringsToSymbol: 'Invoice'.
	query := namespace implementorsQueryForSelector: #size.

	self assert: implementors equals: #('Accounting::Invoice>>size').
	self assert: senders equals: #('Accounting::Invoice>>size').
	self assert: references equals: #('Accounting::Invoice>>size').
	self assert: query class equals: GbsNamespaceScopedMethodQuery.
	self assert: query references equals: #('Accounting::Invoice>>size').
	self assert: (query title includesSubstring: 'Namespace Implementors of size')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeEntryRelativeActionsNormalizeAgainstFeaturePath [
	| mockSession entry required loaded |
	required := false.
	loaded := false.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'requireFileNamed:')
			ifTrue: [
				required := true.
				self assert: (script includesSubstring: 'app/shared.rb').
				self deny: (script includesSubstring: '../shared.rb').
				^ 'required' ].
		(script includesSubstring: 'loadFileNamed:')
			ifTrue: [
				loaded := true.
				self assert: (script includesSubstring: 'support/bootstrap.rb').
				self deny: (script includesSubstring: '../../support/bootstrap.rb').
				^ 'loaded' ].
		self fail ].
	entry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb'.

	self assert: (entry requireRelative: '../shared.rb' using: mockSession rubyRuntime) equals: 'required'.
	self assert: (entry loadRelative: '../../support/bootstrap.rb' using: mockSession rubyRuntime) equals: 'loaded'.
	self assert: required.
	self assert: loaded
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadMirrorResetAndRetryRegistrationUseLifecycleScripts [
	| mockSession namespace autoload resetResult retryResult |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Array with: fileName with: fileWasReset')
			ifTrue: [
				self assert: (script includesSubstring: 'Autoload registration is not recoverable.').
				^ #('lib/lazy_thing.rb' true) ].
		(script includesSubstring: 'removeConst: name asSymbol')
			ifTrue: [
				self assert: (script includesSubstring: 'transientNameSpaceForStore: false').
				^ 'lib/lazy_thing.rb' ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'autoloadEntries' put: #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).

	resetResult := autoload resetRegistration.
	retryResult := autoload retryRegistration.

	self assert: autoload canResetRegistration.
	self assert: autoload canRetryRegistration.
	self assert: autoload retryStateLabel equals: 'Recoverable'.
	self assert: resetResult equals: 'lib/lazy_thing.rb'.
	self assert: retryResult first equals: 'lib/lazy_thing.rb'.
	self assert: retryResult second equals: true.
	self assert: (namespace instVarNamed: 'autoloadEntries') isNil
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeReportBuildsProvenanceGraphAndRelativeActions [
	| mockSession namespace graph entry action |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	graph := (mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil) provenanceGraph.
	entry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb'.
	action := entry requireRelativeActionFor: '../shared.rb' using: mockSession rubyRuntime.

	self assert: graph links size equals: 4.
	self assert: (graph text includesSubstring: 'Absolute Load Path -> /opt/demo/lib').
	self assert: (graph text includesSubstring: 'Transient Feature -> app/models/invoice.rb').
	self assert: (graph text includesSubstring: 'LazyThing -> lib/lazy_thing.rb').
	self assert: action actionLabel equals: 'require_relative'.
	self assert: action resolvedPath equals: 'app/shared.rb'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeReportBuildsProvenanceActionsForFeaturesAndAutoloadRecovery [
	| mockSession namespace graph |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [
				^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration')) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	graph := (mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil) provenanceGraph.

	self assert: graph actions size equals: 8.
	self assert: (graph text includesSubstring: 'Actions').
	self assert: (graph text includesSubstring: 'require app/models/invoice.rb').
	self assert: (graph text includesSubstring: 'load config/boot.rb').
	self assert: (graph text includesSubstring: 'recover autoload LazyThing').
	self assert: (graph text includesSubstring: 'reset autoload LazyThing').
	self assert: (graph text includesSubstring: 'retry autoload [transient-reset] LazyThing').
	self assert: (graph text includesSubstring: 'retry autoload [persistent-after-reset] LazyThing')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRubyRuntimeProvenanceGraphNavigatesEntryLinksAndActions [
	| mockSession namespace report graph featureEntry autoloadEntry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [
				^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration' 'A transient cache entry remains from a failed or interrupted autoload attempt.' 'lib/lazy_thing.rb' 'persistent-after-reset')) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	report := mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil.
	graph := report provenanceGraph.
	featureEntry := report loadedFeatureEntries first.
	autoloadEntry := report autoloadRegistrations first.

	self assert: (graph linksForEntry: featureEntry) size equals: 1.
	self assert: (graph actionsForEntry: featureEntry) size equals: 2.
	self assert: (graph actionsForEntry: autoloadEntry) size equals: 4.
	self assert: (graph entriesForSourceLabel: 'Transient Feature') size equals: 1.
	self assert: ((graph linksToTargetLabel: 'lib/lazy_thing.rb') anySatisfy: [ :each | each entry = autoloadEntry ])
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadMirrorFailureStateLabelsDifferentiatePendingAndRecoverableFailure [
	| namespace pending recoverable cached recoverableEntry |
	namespace := GbsRemoteNamespaceMirror topLevelOn: CoreMockGbsSession new.
	pending := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9101 nil false false).
	recoverable := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' false true).
	cached := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 nil true false).
	recoverableEntry := GbsRubyAutoloadRegistrationEntry on: recoverable.

	self assert: pending failureStateLabel equals: 'Awaiting First Load'.
	self deny: pending hasFailedRegistration.
	self assert: recoverable failureStateLabel equals: 'Persistent Recovery Required'.
	self assert: recoverable hasFailedRegistration.
	self assert: cached failureStateLabel equals: 'Transient Cache Reset Required'.
	self assert: (recoverableEntry displayString includesSubstring: '<Persistent Recovery Required>')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadMirrorExposesFailureDetailAndRetryDetail [
	| namespace autoload entry |
	namespace := GbsRemoteNamespaceMirror topLevelOn: CoreMockGbsSession new.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration' 'A transient cache entry remains from a failed or interrupted autoload attempt.' 'lib/lazy_thing.rb' 'persistent-after-reset').
	entry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: autoload failureDetail equals: 'Persistent registration can recover lib/lazy_thing.rb'.
	self assert: autoload retryDetailLabel equals: 'Reset transient cache, then recover persistent registration.'.
	self assert: autoload failureSourceLabel equals: 'Transient Cache + Persistent Registration'.
	self assert: autoload failureMessage equals: 'A transient cache entry remains from a failed or interrupted autoload attempt.'.
	self assert: autoload lastAttemptedFile equals: 'lib/lazy_thing.rb'.
	self assert: autoload retrySourceKind equals: 'persistent-after-reset'.
	self assert: autoload retrySourceChoices equals: #('transient-reset' 'persistent-after-reset').
	self assert: entry failureDetail equals: autoload failureDetail.
	self assert: entry failureMessage equals: autoload failureMessage.
	self assert: entry retryDetailLabel equals: autoload retryDetailLabel.
	self assert: entry retrySourceKind equals: autoload retrySourceKind.
	self assert: (entry displayString includesSubstring: 'Persistent registration can recover lib/lazy_thing.rb')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadFailureBuildsExceptionObjectAndBacktrace [
	| session namespace autoload failure exception metadata |
	session := CoreMockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: session.
	metadata := {
		'LazyThing'.
		nil.
		false.
		9101.
		'lib/lazy_thing.rb'.
		true.
		true.
		'Persistent registration can recover lib/lazy_thing.rb'.
		'Reset transient cache, then recover persistent registration.'.
		'Transient Cache + Persistent Registration'.
		'autoload failed'.
		'lib/lazy_thing.rb'.
		'persistent-after-reset'.
		9501.
		'LazyThingError: boom', String lf, 'demo.rb:12' }.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: metadata.
	failure := autoload failure.
	exception := failure exceptionObject.

	self assert: failure retrySourceChoices equals: #('transient-reset' 'persistent-after-reset').
	self assert: failure retrySourceKind equals: 'persistent-after-reset'.
	self assert: exception oop equals: 9501.
	self assert: exception hasRemoteObject.
	self assert: exception hasBacktrace.
	self assert: exception backtraceText equals: 'LazyThingError: boom', String lf, 'demo.rb:12'.
	self assert: exception backtraceLines asArray equals: #('LazyThingError: boom' 'demo.rb:12').
	self assert: exception backtraceLines last equals: 'demo.rb:12'.
	self assert: failure failureBacktraceText equals: exception backtraceText.
	self assert: (exception text includesSubstring: 'Backtrace').
	self assert: (exception text includesSubstring: 'demo.rb:12')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteAutoloadFailureBuildsBacktraceEntryObjectsAndRetryActions [
	| session namespace autoload failure entry |
	session := CoreMockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: session.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: {
			'LazyThing'. nil. false. 9101. 'lib/lazy_thing.rb'. true. true.
			'Persistent registration can recover lib/lazy_thing.rb'.
			'Reset transient cache, then recover persistent registration.'.
			'Transient Cache + Persistent Registration'.
			'autoload failed'.
			'lib/lazy_thing.rb'.
			'persistent-after-reset'.
			9501.
			'LazyThingError: boom', String lf, 'demo.rb:12', String lf, 'lib/lazy_thing.rb:3' }.
	failure := autoload failure.
	entry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: failure backtraceEntries size equals: 3.
	self assert: failure backtraceEntries second fileName equals: 'demo.rb'.
	self assert: failure backtraceEntries second lineNumber equals: 12.
	self assert: failure retryActionChoices size equals: 2.
	self assert: entry failureBacktraceEntries last fileName equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorAutoloadEntriesScriptIncludesFailureExceptionMetadata [
	| mockSession namespace |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#lastException').
		self assert: (script includesSubstring: '#lastExceptionBacktrace').
		^ #() ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	self assert: namespace autoloadMirrors equals: #()
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRepositoryNamespaceMirrorRetryAutoloadUsingSourceKindBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'selectedSource := sourceKind').
		self assert: (script includesSubstring: '''persistent-after-reset''').
		self assert: (script includesSubstring: 'selectedSource = ''transient-reset''').
		self assert: (script includesSubstring: 'selectedSource = ''persistent-after-reset''').
		^ #('lib/lazy_thing.rb' true 'persistent-after-reset') ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	result := namespace
		retryAutoload: 'LazyThing'
		usingSourceKind: 'persistent-after-reset'.

	self assert: result third equals: 'persistent-after-reset'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcObjectForOopExposesMetadataAndInvocation [
	| mockSession proc result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [ ^ #('ExecBlock2' 2 true 'demo.rb:12' 'proc { |a, b| a + b }') ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :targetOop |
		self assert: message selector equals: #call.
		self assert: message arguments asArray equals: #(1 2).
		self assert: targetOop equals: 9001.
		^ 'ok' ].

	proc := mockSession procObjectForOop: 9001.
	result := proc value: 1 value: 2.

	self assert: proc exists.
	self assert: proc isExecBlock.
	self assert: proc arity equals: 2.
	self assert: proc bindingDisplayString equals: 'execBlock'.
	self assert: proc sourceLocation equals: 'demo.rb:12'.
	self assert: proc sourceCode equals: 'proc { |a, b| a + b }'.
	self assert: result equals: 'ok'
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testRemoteMethodObjectToProcBuildsRemoteProcObject [
	| mockSession methodObject proc |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'receiver := Object _objectForOop: 9001')
			ifTrue: [
				self assert: (script includesSubstring: 'receiver method: #foo').
				^ '9101' ].
		(script includesSubstring: 'Object _objectForOop: 9101')
			ifTrue: [ ^ #('Proc' 0 false 'demo.rb:1' 'proc { foo }') ].
		self fail ].
	methodObject := (GbsRemoteMethodObject
		on: mockSession
		class: 'DemoClass'
		selector: #foo
		classSide: false)
			bindTo: (GbsProxy oop: 9001 session: mockSession).

	proc := methodObject toProc.

	self assert: proc class equals: GbsRemoteProcObject.
	self assert: proc oop equals: 9101.
	self assert: proc isExecBlock not
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcObjectForOopSpecializesExecBlocksAndEnforcesArity [
	| mockSession proc |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [ ^ #('ExecBlock2' 2 true 'demo.rb:12' 'proc { |a, b| a + b }') ].
		self fail ].

	proc := mockSession procObjectForOop: 9001.

	self assert: proc class equals: GbsRemoteExecBlockObject.
	self assert: proc isExecBlock.
	self assert: proc isLambdaLike.
	self should: [ proc value: 1 ] raise: Error
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcBindingObjectExposesReceiverAndCapturedLocals [
	| mockSession proc binding associations |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [
				^ #('Proc' 1 false 'demo.rb:12' 'proc { |invoice| invoice total }' 9101 #('invoice' 'count') #(9201 nil) #('a DemoInvoice' '42')) ].
		self fail ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.
	associations := binding localAssociations.

	self assert: binding receiverOop equals: 9101.
	self assert: binding receiverProxy oop equals: 9101.
	self assert: binding hasCapturedLocals.
	self assert: proc hasCapturedLocals.
	self assert: proc localNames equals: #('invoice' 'count').
	self assert: associations first key equals: 'invoice'.
	self assert: associations first value oop equals: 9201.
	self assert: associations second key equals: 'count'.
	self assert: associations second value equals: '42'.
	self assert: (mockSession bindingObjectForProcOop: 9001) class equals: GbsRemoteBindingObject
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcBindingObjectEvaluatesRubySourceAndLocals [
	| mockSession proc binding |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'perform: #eval withArguments:')
			ifTrue: [
				self assert: (script includesSubstring: '''demo.rb''').
				self assert: (script includesSubstring: '12 }').
				(script includesSubstring: '''invoice''')
					ifTrue: [ ^ 42 ].
				^ 57 ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { |invoice| invoice total }' 9101 #('invoice' 'count') #(9201 nil) #('a DemoInvoice' '42')) ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: (binding evaluate: 'invoice.total + count') equals: 57.
	self assert: (binding localValueNamed: 'invoice') equals: 42.
	self assert: binding lexicalScopeNames equals: #('invoice' 'count').
	self assert: binding lexicalScopeAssociations size equals: 2
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcBindingObjectSupportsLocalMutationAndLexicalMetadata [
	| mockSession proc binding |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'binding lexicalPath')
			ifTrue: [ ^ '#(''Demo'' ''Closures'')' ].
		(script includesSubstring: 'binding methodDefTarget')
			ifTrue: [ ^ 'Demo::Closures' ].
		(script includesSubstring: 'binding forModuleEval')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'perform: #eval withArguments:')
			ifTrue: [
				(script includesSubstring: 'invoice = (99)')
					ifTrue: [ ^ 99 ].
				^ 57 ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { invoice }' 9101 #('invoice') #(9201) #('a DemoInvoice')) ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'binding methodDefTarget').
		^ 9301 ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: binding selfProxy oop equals: 9101.
	self assert: binding forModuleEval.
	self assert: binding lexicalPathDisplayString equals: '#(''Demo'' ''Closures'')'.
	self assert: binding methodDefTargetDisplayString equals: 'Demo::Closures'.
	self assert: binding methodDefTargetProxy oop equals: 9301.
	self assert: (binding setLocalNamed: 'invoice' to: 99) equals: 99
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testProcBindingObjectBuildsClosureIdentityAndText [
	| mockSession proc binding |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'binding lexicalPath')
			ifTrue: [ ^ '#(''Demo'' ''Closures'')' ].
		(script includesSubstring: 'binding methodDefTarget')
			ifTrue: [ ^ 'Demo::Closures' ].
		(script includesSubstring: 'binding forModuleEval')
			ifTrue: [ ^ true ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { invoice }' 9101 #('invoice') #(9201) #('a DemoInvoice')) ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | 9301 ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: (binding closureIdentityString includesSubstring: 'binding@demo.rb:12').
	self assert: (binding text includesSubstring: 'Lexical Path: #(''Demo'' ''Closures'')').
	self assert: (binding text includesSubstring: 'Method Target: Demo::Closures').
	self assert: (binding text includesSubstring: 'Receiver OOP: 9101').
	self assert: (proc text includesSubstring: 'Proc [arity=1]').
	self assert: (proc text includesSubstring: 'invoice =>')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectSpaceDiagnosticsFinalizerRegistryReportIncludesReferencers [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: mockSession ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: mockSession } ].
		self fail ].

	report := mockSession objectSpaceDiagnostics finalizerRegistryReport.

	self assert: report referencers size equals: 1.
	self assert: report referencers first oop equals: 9101.
	self assert: (report text includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (report text includesSubstring: 'oop=9101')
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectSpaceDiagnosticsFacadeBuildsTypedWellKnownSlotsWithTags [
	| mockSession diagnostics slot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 19') ifTrue: [ ^ #(1 2 3) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		slot := diagnostics slotNamed: 'maglev finalizer registry'.

		self assert: slot class equals: GbsFinalizerRegistrySessionStateSlot.
		self assert: slot isWellKnown.
		self assert: slot discoverySource equals: #registered.
		self assert: (slot hasTag: #maglev).
		self assert: (slot hasTag: #finalizerRegistry)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionMagLevTest >> testObjectSpaceDiagnosticsFacadeRegistersMaglevCompilerAndStackSlots [
	| mockSession diagnostics compilerSlot targetStackSlot evalArgsSlot currentTargetSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 1') ifTrue: [ ^ 'compiler-state' ].
			(script includesSubstring: 'key := 3') ifTrue: [ ^ #(1 2 3) ].
			(script includesSubstring: 'key := 6') ifTrue: [ ^ #(4 5) ].
			(script includesSubstring: 'key := 7') ifTrue: [ ^ 'method-target' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		compilerSlot := diagnostics slotNamed: 'ruby compiler state'.
		targetStackSlot := diagnostics slotNamed: 'ruby method definition target stack'.
		evalArgsSlot := diagnostics slotNamed: 'ruby eval arguments stack'.
		currentTargetSlot := diagnostics slotNamed: 'ruby current method definition target'.

		self assert: compilerSlot class equals: GbsCompilerStateSessionStateSlot.
		self assert: targetStackSlot class equals: GbsStackSessionStateSlot.
		self assert: evalArgsSlot class equals: GbsStackSessionStateSlot.
		self assert: currentTargetSlot class equals: GbsThreadStateSessionStateSlot
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]
