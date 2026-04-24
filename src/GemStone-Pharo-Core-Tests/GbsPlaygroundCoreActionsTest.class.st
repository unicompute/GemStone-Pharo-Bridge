Class {
	#name : 'GbsPlaygroundCoreActionsTest',
	#superclass : 'TestCase',
	#classVars : [
		'HarnessState'
	],
	#instVars : [
		'previousSession',
		'playgroundActionsClass',
		'originalHarnessMethods'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> dequeueRequestAnswerOr: defaultString [
	| answers |
	answers := self harnessRequestAnswers.
	^ answers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ answers removeFirst ]
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> enqueueHarnessRequestAnswer: aStringOrNil [
	self harnessRequestAnswers add: aStringOrNil
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> harnessRequestAnswers [
	^ self
		harnessStateAt: #requestAnswers
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> harnessState [
	^ HarnessState ifNil: [ HarnessState := Dictionary new ]
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> harnessStateAt: aKey [
	^ self harnessState at: aKey ifAbsent: [ nil ]
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> harnessStateAt: aKey ifAbsentPut: aBlock [
	^ self harnessState at: aKey ifAbsentPut: aBlock
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> harnessStateAt: aKey put: aValue [
	^ self harnessState at: aKey put: aValue
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> recordInfoMessage: aString [
	self harnessStateAt: #lastInfoMessage put: aString asString.
	^ aString asString
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> recordInspectOop: anOop session: aSession [
	self harnessStateAt: #lastInspectedOop put: anOop.
	self harnessStateAt: #lastInspectedSession put: aSession.
	^ anOop
]

{ #category : 'harness' }
GbsPlaygroundCoreActionsTest class >> resetHarnessState [
	HarnessState := Dictionary new.
	self harnessStateAt: #requestAnswers put: OrderedCollection new
]

{ #category : 'private' }
GbsPlaygroundCoreActionsTest >> compilePlaygroundActionsHarnessMethodsOn: aMetaclass [
	aMetaclass
		compile: 'inspectOop: anOop session: aSession
	^ GbsPlaygroundCoreActionsTest recordInspectOop: anOop session: aSession'
		classified: 'testing'.
	aMetaclass
		compile: 'lastInspectedOop
	^ GbsPlaygroundCoreActionsTest harnessStateAt: #lastInspectedOop'
		classified: 'accessing'.
	aMetaclass
		compile: 'lastInspectedSession
	^ GbsPlaygroundCoreActionsTest harnessStateAt: #lastInspectedSession'
		classified: 'accessing'.
	aMetaclass
		compile: 'lastInfoMessage
	^ GbsPlaygroundCoreActionsTest harnessStateAt: #lastInfoMessage'
		classified: 'accessing'.
	aMetaclass
		compile: 'enqueueRequestAnswer: aStringOrNil
	^ GbsPlaygroundCoreActionsTest enqueueHarnessRequestAnswer: aStringOrNil'
		classified: 'testing'.
	aMetaclass
		compile: 'inform: aString
	^ GbsPlaygroundCoreActionsTest recordInfoMessage: aString'
		classified: 'helpers'.
	aMetaclass
		compile: 'requestInput: prompt initialAnswer: defaultString
	^ GbsPlaygroundCoreActionsTest dequeueRequestAnswerOr: defaultString'
		classified: 'helpers'.
	aMetaclass
		compile: 'resetHarness
	^ GbsPlaygroundCoreActionsTest resetHarnessState'
		classified: 'testing'
]

{ #category : 'private' }
GbsPlaygroundCoreActionsTest >> harnessSelectors [
	^ #(
		inspectOop:session:
		lastInspectedOop
		lastInspectedSession
		lastInfoMessage
		enqueueRequestAnswer:
		inform:
		requestInput:initialAnswer:
		resetHarness)
]

{ #category : 'private' }
GbsPlaygroundCoreActionsTest >> requirePlaygroundActionsSelector: aSelector [
	(playgroundActionsClass class canUnderstand: aSelector) ifFalse: [
		self skip: 'Requires MagLev playground extensions.' ]
]

{ #category : 'private' }
GbsPlaygroundCoreActionsTest >> installHarnessOnPlaygroundActionsClass [
	originalHarnessMethods := Dictionary new.
	self harnessSelectors do: [ :selector |
		| method protocol |
		method := playgroundActionsClass class
			compiledMethodAt: selector
			ifAbsent: [ nil ].
		protocol := method
			ifNil: [ nil ]
			ifNotNil: [
				[ playgroundActionsClass class organization categoryOfElement: selector ]
					on: Error
					do: [ 'as yet unclassified' ] ].
		originalHarnessMethods at: selector put: {
			method ifNotNil: [ method sourceCode ].
			protocol } ].
	self compilePlaygroundActionsHarnessMethodsOn: playgroundActionsClass class
]

{ #category : 'private' }
GbsPlaygroundCoreActionsTest >> restoreHarnessOnPlaygroundActionsClass [
	originalHarnessMethods ifNil: [ ^ self ].
	originalHarnessMethods keysAndValuesDo: [ :selector :spec |
		spec first
			ifNil: [
				[ playgroundActionsClass class removeSelector: selector ]
					on: Error
					do: [ ] ]
			ifNotNil: [
				playgroundActionsClass class
					compile: spec first
					classified: spec second ] ].
	originalHarnessMethods := nil
]

{ #category : 'running' }
GbsPlaygroundCoreActionsTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession.
	playgroundActionsClass := GbsPlaygroundActions.
	self installHarnessOnPlaygroundActionsClass.
	playgroundActionsClass resetHarness
]

{ #category : 'running' }
GbsPlaygroundCoreActionsTest >> tearDown [
	playgroundActionsClass ifNotNil: [ self restoreHarnessOnPlaygroundActionsClass ].
	playgroundActionsClass := nil.
	GbsPlaygroundCoreActionsTest resetHarnessState.
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: session. GbsProxy oop: 9202 session: session } ].
		self fail ].
	GbsSessionParameters currentSession: session.
	playgroundActionsClass
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: (playgroundActionsClass gsBrowseObjectsInMemoryReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseSessionStateKeysReportUsesDiagnosticsFacade [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	GbsSessionParameters currentSession: session.
	playgroundActionsClass enqueueRequestAnswer: '19, 21'.

	self assert: (playgroundActionsClass gsBrowseSessionStateKeysReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| session presenter staleEntry |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	staleEntry := GbsTypedWrapperLifecycleEntry
		wrapperClass: nil
		clientName: 'ClientThing'
		serverName: 'ServerThing'
		source: 'autoload'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 2
		remoteNumberOfVersions: 2
		status: #stale.
	session stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseStaleTypedWrapperLifecycleReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #typedWrapperLifecycleReportText put: [
		'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing' ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseTypedWrapperLifecycleReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsInspectItUsesExecuteScriptAndReturnOop [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	presenter selectedText: '42'.

	session stubs
		at: #executeScriptAndReturnOop
		put: [ :script |
			self assert: script equals: '42'.
			9001 ].
	session stubs
		at: #apiGciExecuteStrContextEnv
		put: [ :script :context :env |
			self fail: 'Playground inspectIt should use executeScriptAndReturnOop, not serverInterface.' ].
	GbsSessionParameters currentSession: session.

	playgroundActionsClass gsInspectItIn: presenter.

	self assert: playgroundActionsClass lastInspectedOop equals: 9001.
	self assert: playgroundActionsClass lastInspectedSession == session
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsInspectSessionStateKeyRejectsNonNumericInput [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	GbsSessionParameters currentSession: session.
	playgroundActionsClass enqueueRequestAnswer: 'abc'.

	self deny: (playgroundActionsClass gsInspectSessionStateKeyIn: presenter).
	self assert: playgroundActionsClass lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: playgroundActionsClass lastInspectedOop isNil
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsInspectSessionStateKeyUsesSessionFacade [
	| session presenter |
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'key := 21').
			^ GbsProxy oop: 9701 session: session ].
	GbsSessionParameters currentSession: session.
	playgroundActionsClass enqueueRequestAnswer: '21'.

	self assert: (playgroundActionsClass gsInspectSessionStateKeyIn: presenter).
	self assert: playgroundActionsClass lastInspectedOop equals: 9701.
	self assert: playgroundActionsClass lastInspectedSession == session
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseRubyLoadPathReportUsesRuntimeReport [
	| session presenter |
	self requirePlaygroundActionsSelector: #gsBrowseRubyLoadPathReportIn:.
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseRubyLoadPathReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| session presenter |
	self requirePlaygroundActionsSelector: #gsBrowseRubyLoadedFeaturesReportIn:.
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseRubyLoadedFeaturesReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| session presenter |
	self requirePlaygroundActionsSelector: #gsBrowseRubyPersistentLoadedFeaturesReportIn:.
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseRubyPersistentLoadedFeaturesReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| session presenter |
	self requirePlaygroundActionsSelector: #gsBrowseTopLevelAutoloadRegistrationsReportIn:.
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseTopLevelAutoloadRegistrationsReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'DemoConst -> demo/file [Pending]')
]

{ #category : 'tests' }
GbsPlaygroundCoreActionsTest >> testGsBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| session presenter |
	self requirePlaygroundActionsSelector: #gsBrowseMaglevFinalizerRegistryReportIn:.
	session := CoreMockGbsSession new.
	presenter := CoreMockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: session ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: session } ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (playgroundActionsClass gsBrowseMaglevFinalizerRegistryReportIn: presenter).
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (playgroundActionsClass lastInfoMessage includesSubstring: 'oop=9101')
]
