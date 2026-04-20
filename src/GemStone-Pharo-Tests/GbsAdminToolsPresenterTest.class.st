Class {
	#name : 'GbsAdminToolsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'createUserPresenter',
		'connectorBrowserPresenter',
		'namespacesPresenter',
		'securityPoliciesPresenter',
		'userListPresenter',
		'userInfoPresenter',
		'previousConfiguration',
		'previousCurrentSession',
		'previousConnectorRegistries'
		],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsAdminToolsPresenterTest >> setUp [
	| savedCurrent |
	super setUp.
	previousConfiguration := GbsConfiguration current.
	previousCurrentSession := GbsSessionParameters currentSession.
	previousConnectorRegistries := self snapshotConnectorRegistries.
	GbsSessionManager resetConnectorState.
	createUserPresenter := GbsCreateUserPresenter new.
	connectorBrowserPresenter := GbsConnectorBrowserPresenter new.
	namespacesPresenter := GbsNamespacesPresenter new.
	securityPoliciesPresenter := GbsSecurityPoliciesPresenter new.
	savedCurrent := GbsSessionParameters currentSession.
	GbsSessionParameters currentSession: nil.
	[
		userListPresenter := GbsUserListPresenter new.
	] ensure: [
		GbsSessionParameters currentSession: savedCurrent ].
	userInfoPresenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ nil ]
]

{ #category : 'running' }
GbsAdminToolsPresenterTest >> tearDown [
	self restoreConnectorRegistries.
	GbsSessionParameters currentSession: previousCurrentSession.
	previousConfiguration ifNotNil: [ GbsConfiguration current: previousConfiguration ].
	super tearDown
]

{ #category : 'running' }
GbsAdminToolsPresenterTest >> restoreConnectorRegistries [
	previousConnectorRegistries ifNil: [ ^ self ].
	previousConnectorRegistries keysAndValuesDo: [ :key :value |
		value
			ifNil: [ Smalltalk globals removeKey: key ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: key put: value ] ].
	previousConnectorRegistries := nil
]

{ #category : 'running' }
GbsAdminToolsPresenterTest >> snapshotConnectorRegistries [
	| keys |
	keys := #(
		GbsFastConnectorRegistry
		GbsConnectorObjectRegistry
		GbsConnectorConnectionRegistry
		GbsConnectorClassMappingRegistry
		GbsConnectorPostConnectActionRegistry
		GbsSessionConnectorRegistry
	).
	^ Dictionary newFromPairs: (keys flatCollect: [ :each |
		{ each. (Smalltalk globals at: each ifAbsent: [ nil ]) } ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testCreateUserLiteralStringEscapesEmbeddedQuote [
	self
		assert: (createUserPresenter literalString: 'o''connor')
		equals: '''o''''connor'''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testCreateUserScriptIncludesEscapedCredentials [
	| script |
	script := createUserPresenter
		scriptToCreateUser: 'da''ta'
		password: 'pw''1'.

	self assert: (script includesSubstring: '''da''''ta''').
	self assert: (script includesSubstring: '''pw''''1''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesParseRowsParsesTabSeparatedColumns [
	| rows |
	rows := namespacesPresenter parseRows: '1', Character tab asString, 'UserGlobals', Character tab asString, 'SymbolDictionary', String lf, '2', Character tab asString, 'Globals', Character tab asString, 'SymbolDictionary'.

	self assert: rows size equals: 2.
	self assert: (rows first at: 1) equals: '1'.
	self assert: (rows first at: 2) equals: 'UserGlobals'.
	self assert: (rows first at: 3) equals: 'SymbolDictionary'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshUsesNamespaceMirrors [
	| mockSession fakeTable items |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		self fail ].

	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeTable.

	namespacesPresenter refreshNamespaces.
	items := fakeTable items.

	self assert: items size equals: 1.
	self assert: items first class equals: GbsRemoteNamespaceMirror.
	self assert: items first displayName equals: 'UserGlobals'.
	self assert: items first className equals: 'SymbolDictionary'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesSynchronizesDetailsAndRuntime [
	| mockSession previousNamespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		((script includesSubstring: 'System myUserProfile symbolList at: 1')
			and: [ script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1' ])
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		((script includesSubstring: 'System myUserProfile symbolList at: 1')
			and: [ script includesSubstring: 'entries add: (Array with: each asString' ])
			ifTrue: [ ^ #(
				#('Invoice' 7101 'Invoice' nil 'Invoice' 'Accounting::Invoice')
				#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ].
		self fail ].
	previousNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { previousNamespace }.
	fakeNamespaceTable selectedItem: previousNamespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.

	namespacesPresenter refreshNamespaces.

	self assert: fakeNamespaceTable selectedItem notNil.
	self assert: fakeConstantsTable items size equals: 2.
	self assert: fakeAutoloadTable items size equals: 1.
	self assert: (fakeText text includesSubstring: 'Selected Namespace: UserGlobals').
	self assert: (fakeText text includesSubstring: 'Selected Constant:').
	self assert: (fakeText text includesSubstring: '$LOAD_PATH')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseNamespaceReferencesUsesScopedQueryResults [
	| presenter mockSession namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	presenter := TestableGbsNamespacesPresenter new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'referencesTo:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: nil'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('Invoice' nil nil nil nil nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { namespace }.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable items: { constant }.
	fakeConstantsTable selectedItem: constant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter browseNamespaceReferencesToSelectedConstant.
	self assert: presenter lastMethodQueryReferences equals: #('Accounting::Invoice>>size').
	self assert: (presenter lastMethodQueryTitle includesSubstring: 'Namespace References to Invoice')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseNamespaceImplementorsUsesScopedQueryResults [
	| presenter mockSession namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	presenter := TestableGbsNamespacesPresenter new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'implementorsOf:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: nil'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { namespace }.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.
	presenter enqueueRequestAnswer: 'size'.

	self assert: presenter browseNamespaceImplementorsOfPromptedSelector.
	self assert: presenter lastMethodQueryReferences equals: #('Accounting::Invoice>>size').
	self assert: (presenter lastMethodQueryTitle includesSubstring: 'Namespace Implementors of size')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesClearsStaleDetailsAndRuntimeContext [
	| mockSession selectedNamespace oldConstant oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(2 5002 'Globals' nil 'SymbolDictionary' nil)) ].
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	selectedNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	oldConstant := GbsRemoteConstantMirror
		on: selectedNamespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	oldAutoload := GbsRemoteAutoloadMirror
		on: selectedNamespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9101).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { selectedNamespace }.
	fakeNamespaceTable selectedItem: selectedNamespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable items: { oldConstant }.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable items: { oldAutoload }.
	fakeAutoloadTable selectedItem: oldAutoload.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'stale'.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.

	namespacesPresenter refreshNamespaces.

	self assert: fakeNamespaceTable selectedItem isNil.
	self assert: fakeConstantsTable items isEmpty.
	self assert: fakeAutoloadTable items isEmpty.
	self deny: (fakeText text includesSubstring: 'Selected Namespace:').
	self deny: (fakeText text includesSubstring: 'Selected Constant:').
	self deny: (fakeText text includesSubstring: 'Selected Autoload:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsUsesNamespaceMirrors [
	| mockSession fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		((script includesSubstring: 'System myUserProfile symbolList at: 1')
			and: [ script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1' ])
			ifTrue: [ ^ #(
				#('LazyThing' 'lib/lazy_thing.rb' false 9101)
			) ].
		((script includesSubstring: 'System myUserProfile symbolList at: 1')
			and: [ script includesSubstring: 'entries add: (Array with: each asString' ])
			ifTrue: [ ^ #(
				#('Invoice' 7101 'Invoice' nil 'Invoice' 'Accounting::Invoice')
				#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)
			) ].
		self fail ].

	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshNamespaces.
	fakeNamespaceTable selectedItem: fakeNamespaceTable items first.
	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeConstantsTable items size equals: 2.
	self assert: fakeConstantsTable items first name equals: 'Invoice'.
	self assert: fakeConstantsTable items first targetDisplayName equals: 'Accounting::Invoice'.
	self assert: fakeAutoloadTable items size equals: 1.
	self assert: fakeAutoloadTable items first name equals: 'LazyThing'.
	self assert: fakeAutoloadTable items first autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: fakeAutoloadTable items first oop equals: 9101.
	self assert: fakeAutoloadTable items first stateLabel equals: 'Pending'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesPreservesSelectedNamespaceRow [
	| mockSession fakeTable selectedNamespace replacementNamespace |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	selectedNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	replacementNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		self fail ].
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable items: { selectedNamespace }.
	fakeTable selectedItem: selectedNamespace.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeTable.

	namespacesPresenter refreshNamespaces.

	self assert: fakeTable selectedItem ~~ selectedNamespace.
	self assert: (fakeTable items anySatisfy: [ :each | each == fakeTable selectedItem ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesClearsStaleSelectedNamespaceRow [
	| mockSession fakeTable selectedNamespace |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	selectedNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(2 5002 'Globals' nil 'SymbolDictionary' nil)) ].
		self fail ].
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable items: { selectedNamespace }.
	fakeTable selectedItem: selectedNamespace.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeTable.

	namespacesPresenter refreshNamespaces.

	self assert: fakeTable items size equals: 1.
	self assert: fakeTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesUsesAutoloadOwnerWhenNamespaceRowMissing [
	| mockSession fakeNamespaceTable fakeAutoloadTable ownerNamespace autoload |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	ownerNamespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: ownerNamespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 7001 'Object' 'Object' 'RubyNameSpace' 'Object')) ].
		self fail ].
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshNamespaces.

	self assert: fakeNamespaceTable selectedItem notNil.
	self assert: (fakeNamespaceTable items anySatisfy: [ :each | each == fakeNamespaceTable selectedItem ]).
	self assert: fakeNamespaceTable selectedItem oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshNamespacesUsesConstantOwnerWhenNamespaceRowMissing [
	| mockSession fakeNamespaceTable fakeConstantsTable ownerNamespace constant |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	ownerNamespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: ownerNamespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 7001 'Object' 'Object' 'RubyNameSpace' 'Object')) ].
		self fail ].
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshNamespaces.

	self assert: fakeNamespaceTable selectedItem notNil.
	self assert: (fakeNamespaceTable items anySatisfy: [ :each | each == fakeNamespaceTable selectedItem ]).
	self assert: fakeNamespaceTable selectedItem oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsPreservesSelectedAutoloadRow [
	| mockSession namespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	oldAutoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: oldAutoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeAutoloadTable selectedItem notNil.
	self assert: fakeAutoloadTable selectedItem ~~ oldAutoload.
	self assert: (fakeAutoloadTable items anySatisfy: [ :each | each == fakeAutoloadTable selectedItem ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsRestoresNamespaceRowFromSelectedAutoloadOwner [
	| mockSession namespace ownerRow autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	ownerRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { ownerRow }.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeNamespaceTable selectedItem == ownerRow
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsClearsStaleSelectedAutoloadRow [
	| mockSession namespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'constantEntries' put: #().
	namespace instVarNamed: 'autoloadEntries' put: #().
	oldAutoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: oldAutoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeAutoloadTable items isEmpty.
	self assert: fakeAutoloadTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsPreservesSelectedConstantRow [
	| mockSession namespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #().
	oldConstant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeConstantsTable selectedItem notNil.
	self assert: fakeConstantsTable selectedItem ~~ oldConstant.
	self assert: (fakeConstantsTable items anySatisfy: [ :each | each == fakeConstantsTable selectedItem ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsRestoresNamespaceRowFromSelectedConstantOwner [
	| mockSession namespace ownerRow oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	ownerRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #().
	oldConstant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { ownerRow }.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeNamespaceTable selectedItem == ownerRow
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsClearsStaleSelectedConstantRow [
	| mockSession namespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'constantEntries' put: #().
	namespace instVarNamed: 'autoloadEntries' put: #().
	oldConstant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeConstantsTable items isEmpty.
	self assert: fakeConstantsTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsDoesNotCarryAutoloadSelectionAcrossNamespaceChange [
	| mockSession oldNamespace newNamespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	oldNamespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	newNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Accounting nameSpace: 1'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Accounting').
	newNamespace instVarNamed: 'constantEntries' put: #().
	newNamespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9292)).
	oldAutoload := GbsRemoteAutoloadMirror
		on: oldNamespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { oldNamespace. newNamespace }.
	fakeNamespaceTable selectedItem: newNamespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: oldAutoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeAutoloadTable items size equals: 1.
	self assert: fakeAutoloadTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshSelectedNamespaceDetailsDoesNotCarryConstantSelectionAcrossNamespaceChange [
	| mockSession oldNamespace newNamespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	oldNamespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	newNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Accounting nameSpace: 1'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Accounting').
	newNamespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 8101 'Class' nil 'Invoice' 'Accounting::Invoice')).
	newNamespace instVarNamed: 'autoloadEntries' put: #().
	oldConstant := GbsRemoteConstantMirror
		on: oldNamespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Object::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { oldNamespace. newNamespace }.
	fakeNamespaceTable selectedItem: newNamespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshSelectedNamespaceDetails.

	self assert: fakeConstantsTable items size equals: 1.
	self assert: fakeConstantsTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoIncludesSelectedConstantTarget [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Target').
	self assert: (fakeText text includesSubstring: 'Target: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Namespace: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Parent: Accounting').
	self assert: (fakeText text includesSubstring: 'Value Class: Class')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoUsesConstantTargetLabelForAutoloadBackedConstantSelection [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Namespace Source: Selected Constant Owner').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Target').
	self deny: (fakeText text includesSubstring: 'Lookup Base Source: Selected Autoload Target')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoUsesConstantOwnerLookupLabelWhenTargetIsUnavailable [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' nil nil 'lib/invoice.rb' nil nil).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Namespace Source: Selected Constant Owner').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Owner').
	self deny: (fakeText text includesSubstring: 'Lookup Base Source: Selected Namespace')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoUsesAutoloadOwnerLookupLabelWhenTargetIsUnavailable [
	| mockSession fakeText namespace autoload fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' false 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Namespace Source: Selected Autoload Owner').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Autoload Owner').
	self deny: (fakeText text includesSubstring: 'Lookup Base Source: Selected Namespace')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoNormalizesConstantSelectedInAutoloadTable [
	| mockSession fakeText namespace constant fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('LazyThing' 'lib/lazy_thing.rb' false 9191)).
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Autoload: LazyThing').
	self assert: (fakeText text includesSubstring: 'Autoload State: Pending').
	self assert: (fakeText text includesSubstring: 'Autoload File: lib/lazy_thing.rb')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectSelectedAutoloadNormalizesConstantSelectedInAutoloadTable [
	| mockSession presenter namespace constant fakeAutoloadTable |
	mockSession := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('LazyThing' 'lib/lazy_thing.rb' false 9191)).
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil).
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter inspectSelectedAutoload.
	self assert: presenter lastOpenedOop equals: 9191
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesHandleAutoloadSelectionChangedClearsConstantSelection [
	| mockSession fakeText namespace constant autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice').
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter handleAutoloadSelectionChanged.

	self assert: fakeConstantsTable selectedItem isNil.
	self assert: fakeAutoloadTable selectedItem == autoload.
	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias').
	self deny: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesHandleConstantSelectionChangedClearsAutoloadSelection [
	| mockSession fakeText namespace constant autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice').
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter handleConstantSelectionChanged.

	self assert: fakeAutoloadTable selectedItem isNil.
	self assert: fakeConstantsTable selectedItem == constant.
	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias').
	self deny: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesHandleAutoloadSelectionChangedNormalizesAutoloadBackedConstantSelection [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter handleAutoloadSelectionChanged.

	self assert: fakeConstantsTable selectedItem isNil.
	self assert: fakeAutoloadTable selectedItem class equals: GbsRemoteAutoloadMirror.
	self assert: fakeAutoloadTable selectedItem name equals: 'InvoiceAlias'.
	self assert: fakeAutoloadTable selectedItem autoloadFile equals: 'lib/invoice.rb'.
	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias').
	self deny: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesHandleConstantSelectionChangedNormalizesAutoloadMirrorSelection [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: autoload.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter handleConstantSelectionChanged.

	self assert: fakeAutoloadTable selectedItem isNil.
	self assert: fakeConstantsTable selectedItem class equals: GbsRemoteConstantMirror.
	self assert: fakeConstantsTable selectedItem name equals: 'InvoiceAlias'.
	self assert: fakeConstantsTable selectedItem oop equals: 7101.
	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias').
	self deny: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoIncludesLookupBaseWithoutSelectedNamespace [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self deny: (fakeText text includesSubstring: 'Selected Namespace:').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Target').
	self assert: (fakeText text includesSubstring: 'Lookup Base Namespace: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Parent: Accounting').
	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoIncludesSelectedAutoloadDetails [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	autoload
		namespaceMirror
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Autoload State: Loaded').
	self assert: (fakeText text includesSubstring: 'Autoload File: lib/invoice.rb').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Autoload Target').
	self assert: (fakeText text includesSubstring: 'Autoload Target: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Namespace: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Parent: Accounting').
	self assert: (fakeText text includesSubstring: 'Autoload Value Class: Class')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoDoesNotShowAutoloadDetailsForSelectedAutoloadBackedConstant [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Target').
	self deny: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoDoesNotShowConstantDetailsForSelectedLoadedAutoload [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Autoload Target').
	self deny: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoNormalizesAutoloadMirrorSelectedInConstantsTable [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Constant: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Constant Target').
	self deny: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoUsesAutoloadOwnerWhenNamespaceRowIsMissing [
	| mockSession fakeText namespace autoload fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	autoload
		namespaceMirror
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')).
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Namespace: Object').
	self assert: (fakeText text includesSubstring: 'Selected Namespace Source: Selected Autoload Owner').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Autoload Target').
	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoIncludesLoadingAutoloadState [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' nil 9191).
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Selected Autoload: InvoiceAlias').
	self assert: (fakeText text includesSubstring: 'Autoload State: Loading')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoUsesRubyRuntimeSurface [
	| mockSession fakeText |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [
			^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].

	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: GbxFakeTablePresenterForRemoteDebugger new.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Ruby Runtime').
	self assert: (fakeText text includesSubstring: '$LOAD_PATH').
	self assert: (fakeText text includesSubstring: 'app/models').
	self assert: (fakeText text includesSubstring: 'Loaded Features').
	self assert: (fakeText text includesSubstring: 'foo.rb').
	self assert: (fakeText text includesSubstring: 'Persistent Loaded Features').
	self assert: (fakeText text includesSubstring: 'persisted.rb').
	self assert: (fakeText text includesSubstring: 'Session State').
	self assert: (fakeText text includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRequireSelectedFileUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable lastScript |
	mockSession := MockGbsSession new.
	lastScript := ''.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'RubyContext default requireFileNamed: ''foo.rb'' env: 1')
			ifTrue: [
				lastScript := script.
				^ true ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: 'foo.rb'.

	self assert: presenter requireSelectedFile.
	self assert: (lastScript includesSubstring: 'RubyContext default requireFileNamed: ''foo.rb'' env: 1')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRequireSelectedFileInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := MockGbsSession new.
	phase := #before.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'RubyContext default requireFileNamed: ''lazy_thing.rb'' env: 1')
			ifTrue: [
				phase := #after.
				^ true ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ]
							ifFalse: [ #(#('LazyThing' 7101 'Class' nil 'LazyThing' 'LazyThing')) ] ] ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	presenter refreshSelectedNamespaceDetails.
	self assert: fakeAutoloadTable items size equals: 1.
	fakeConstantsTable selectedItem: fakeConstantsTable items first.
	presenter enqueueRequestAnswer: 'lazy_thing.rb'.

	self assert: presenter requireSelectedFile.
	self assert: fakeConstantsTable items first oop equals: 7101.
	self assert: fakeAutoloadTable items isEmpty
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesLoadSelectedFileUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable lastScript |
	mockSession := MockGbsSession new.
	lastScript := ''.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'RubyContext default loadFileNamed: ''bar.rb'' env: 1')
			ifTrue: [
				lastScript := script.
				^ 'loaded' ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: 'bar.rb'.

	self assert: presenter loadSelectedFile.
	self assert: (lastScript includesSubstring: 'RubyContext default loadFileNamed: ''bar.rb'' env: 1')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesLoadSelectedFileInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := MockGbsSession new.
	phase := #before.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'RubyContext default loadFileNamed: ''lazy_thing.rb'' env: 1')
			ifTrue: [
				phase := #after.
				^ 'loaded' ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ]
							ifFalse: [ #(#('LazyThing' 7101 'Class' nil 'LazyThing' 'LazyThing')) ] ] ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	presenter refreshSelectedNamespaceDetails.
	self assert: fakeAutoloadTable items size equals: 1.
	fakeConstantsTable selectedItem: fakeConstantsTable items first.
	presenter enqueueRequestAnswer: 'lazy_thing.rb'.

	self assert: presenter loadSelectedFile.
	self assert: fakeConstantsTable items first oop equals: 7101.
	self assert: fakeAutoloadTable items isEmpty
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesClearPersistentLoadedFeaturesUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable fakeText clearCalls persistentFeatures |
	mockSession := MockGbsSession new.
	clearCalls := 0.
	persistentFeatures := #('persisted.rb').
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ persistentFeatures ].
		script = 'RubyContext clear_persistent_LOADED_FEATURES' ifTrue: [
			clearCalls := clearCalls + 1.
			persistentFeatures := #().
			^ true ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'runtimeText' put: fakeText.

	self assert: presenter clearPersistentLoadedFeatures.
	self assert: clearCalls equals: 1.
	self assert: (fakeText text includesSubstring: 'Persistent Loaded Features').
	self assert: (fakeText text includesSubstring: '(empty)')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRegisterAutoloadUsesSelectedConstantAndPromptedFile [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable lastScript |
	mockSession := MockGbsSession new.
	lastScript := ''.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'respondsTo: #rubyAutoload:file:')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'rubyAutoload: name asSymbol file: file')
			ifTrue: [
				lastScript := script.
				^ 'lib/lazy_thing.rb' ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('LazyThing' nil nil nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter enqueueRequestAnswer: 'lib/lazy_thing.rb'.

	self assert: presenter registerAutoloadForSelectedNamespace.
	self assert: (lastScript includesSubstring: '''LazyThing''').
	self assert: (lastScript includesSubstring: '''lib/lazy_thing.rb''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRegisterAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := MockGbsSession new.
	phase := #before.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'respondsTo: #rubyAutoload:file:')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'rubyAutoload: name asSymbol file: file')
			ifTrue: [
				phase := #after.
				^ 'lib/lazy_thing.rb' ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' nil nil nil nil nil)) ]
							ifFalse: [ #(#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ] ] ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	presenter refreshSelectedNamespaceDetails.
	self assert: fakeAutoloadTable items isEmpty.
	fakeConstantsTable selectedItem: fakeConstantsTable items first.
	presenter enqueueRequestAnswer: 'lib/lazy_thing.rb'.

	self assert: presenter registerAutoloadForSelectedNamespace.
	self assert: fakeAutoloadTable items size equals: 1.
	self assert: fakeAutoloadTable items first autoloadFile equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRequireSelectedAutoloadUsesSelectedEntryFile [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable lastScript |
	mockSession := MockGbsSession new.
	lastScript := ''.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'RubyContext default requireFileNamed: ''lib/lazy_thing.rb'' env: 1')
			ifTrue: [
				lastScript := script.
				^ true ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter requireSelectedAutoload.
	self assert: (lastScript includesSubstring: 'RubyContext default requireFileNamed: ''lib/lazy_thing.rb'' env: 1')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRequireSelectedAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText phase |
	mockSession := MockGbsSession new.
	phase := #before.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''lib/lazy_thing.rb'' env: 1')
			ifTrue: [
				phase := #after.
				^ true ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' 'lib/lazy_thing.rb' false 9191)) ]
							ifFalse: [ #(#('LazyThing' 'lib/lazy_thing.rb' true 9191)) ] ].
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ]
							ifFalse: [ #(#('LazyThing' 7101 'Class' 'lib/lazy_thing.rb' 'LazyThing' 'LazyThing')) ] ] ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.
	presenter instVarNamed: 'runtimeText' put: fakeText.

	presenter refreshSelectedNamespaceDetails.
	self assert: fakeAutoloadTable items first stateLabel equals: 'Pending'.
	fakeAutoloadTable selectedItem: autoload.

	self assert: presenter requireSelectedAutoload.
	self assert: fakeAutoloadTable items first stateLabel equals: 'Loaded'.
	self assert: fakeAutoloadTable items first targetDisplayName equals: 'LazyThing'.
	self assert: (fakeText text includesSubstring: 'Autoload State: Loaded')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRemoveSelectedAutoloadUsesSelectedAutoloadEntry [
	| mockSession presenter namespace constant fakeNamespaceTable fakeAutoloadTable lastScript |
	mockSession := MockGbsSession new.
	lastScript := ''.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1')
			ifTrue: [
				lastScript := script.
				^ true ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter removeSelectedAutoload.
	self assert: (lastScript includesSubstring: '''LazyThing''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRemoveSelectedAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := MockGbsSession new.
	phase := #before.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1')
			ifTrue: [
				phase := #after.
				^ true ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [
						^ phase = #before
							ifTrue: [ #(#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ]
							ifFalse: [ #() ] ] ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	presenter refreshSelectedNamespaceDetails.
	self assert: fakeAutoloadTable items size equals: 1.
	fakeAutoloadTable selectedItem: constant.

	self assert: presenter removeSelectedAutoload.
	self assert: fakeConstantsTable items isEmpty.
	self assert: fakeAutoloadTable items isEmpty
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectSelectedConstantOpensInspectorWorkflow [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('Invoice' 7101 'InvoiceClass' nil).
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	self assert: presenter inspectSelectedConstant.
	self assert: presenter lastOpenedOop equals: 7101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectSelectedAutoloadOpensInspectorWorkflow [
	| mockSession presenter namespace autoload fakeAutoloadTable |
	mockSession := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9191).
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter inspectSelectedAutoload.
	self assert: presenter lastOpenedOop equals: 9191
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectMaglevFinalizerRegistryOpensInspectorWorkflow [
	| mockSession presenter registry |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [ ^ registry ].
		self fail ].
	registry := GbsProxy oop: 9191 session: mockSession.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter inspectMaglevFinalizerRegistry.
	self assert: presenter lastOpenedOop equals: 9191
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectPromptedSessionStateKeyInformsWhenUnset [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21') ifTrue: [ ^ nil ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '21'.

	self deny: presenter inspectPromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Session state key 21 is not set.'.
	self assert: presenter lastOpenedOop isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectPromptedSessionStateKeyRejectsNonNumericInput [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter inspectPromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastOpenedOop isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesInspectPromptedSessionStateKeyUsesSessionFacade [
	| mockSession presenter registry |
	mockSession := MockGbsSession new.
	registry := GbsProxy oop: 9292 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21') ifTrue: [ ^ registry ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '21'.

	self assert: presenter inspectPromptedSessionStateKey.
	self assert: presenter lastOpenedOop equals: 9292
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseTypedWrapperLifecycleReportUsesSessionFacade [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #typedWrapperLifecycleReportText put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing -> ServerThing' ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (presenter lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseTypedWrapperAutoloadReportUsesSessionRegistry [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	[
		GbsSessionManager addConnectorClient: 'DemoClient' server: 'DemoServer' forSession: mockSession.
		self assert: presenter browseTypedWrapperAutoloadReport.
		self assert: (presenter lastInfoMessage includesSubstring: 'Typed Wrapper Autoload').
		self assert: (presenter lastInfoMessage includesSubstring: 'DemoClient -> DemoServer')
	] ensure: [
		GbsSessionManager removeConnectorClient: 'DemoClient' server: 'DemoServer' forSession: mockSession ]
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseStaleTypedWrapperLifecycleReportShowsStaleEntries [
	| mockSession presenter staleEntry |
	mockSession := MockGbsSession new.
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
	mockSession stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseStaleTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (presenter lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshStaleTypedWrappersUsesSessionRefresh [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #refreshStaleTypedWrapperClasses put: [ { GbsTypedProxy. Object } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter refreshStaleTypedWrappers.
	self assert: presenter lastInfoMessage equals: 'Refreshed 2 stale typed wrapper(s).'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshAllTypedWrappersUsesSessionRefresh [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #refreshAllTypedWrapperClasses put: [ { GbsTypedProxy } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter refreshAllTypedWrappers.
	self assert: presenter lastInfoMessage equals: 'Refreshed 1 typed wrapper(s).'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseWrapperActionChooserUsesSelectedWrapperAction [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #refreshAllTypedWrapperClasses put: [ { GbsTypedProxy } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueChooseAnswer: 5.

	self assert: presenter browseWrapperActionChooser.
	self assert: presenter lastInfoMessage equals: 'Refreshed 1 typed wrapper(s).'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '19, 21'.

	self assert: presenter browsePromptedSessionStateKeysReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseRubyLoadPathReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseRubyLoadPathReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Ruby Runtime').
	self assert: (presenter lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (presenter lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseRubyLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseRubyPersistentLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseNamedObjectCacheReportUsesSessionCacheText [
	| mockSession presenter cache |
	mockSession := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession instVarNamed: 'namedObjectCache' put: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseNamedObjectCacheReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (presenter lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesClearNamedObjectCacheClearsSessionCache [
	| mockSession presenter cache |
	mockSession := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession instVarNamed: 'namedObjectCache' put: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter clearNamedObjectCache.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: mockSession namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseSessionStateReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseSessionStateReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Session State').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseNamespaceAutoloadRegistrationsReportUsesSelectedNamespace [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		((script includesSubstring: 'System myUserProfile symbolList at: 1')
			and: [ script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1' ])
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(1 5001 'UserGlobals' nil 'SymbolDictionary' nil).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { namespace }.
	fakeNamespaceTable selectedItem: namespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.

	self assert: presenter browseNamespaceAutoloadRegistrationsReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (presenter lastInfoMessage includesSubstring: 'LazyThing').
	self assert: (presenter lastInfoMessage includesSubstring: 'lib/lazy_thing.rb')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseRuntimeReportChooserUsesSelectedRuntimeAction [
	| mockSession presenter cache |
	mockSession := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession instVarNamed: 'namedObjectCache' put: cache.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueChooseAnswer: 1.

	self assert: presenter browseRuntimeReportChooser.
	self assert: (presenter lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (presenter lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseRuntimeReportChooserCanClearNamedObjectCache [
	| mockSession presenter cache |
	mockSession := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession instVarNamed: 'namedObjectCache' put: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueChooseAnswer: 2.

	self assert: presenter browseRuntimeReportChooser.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: mockSession namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: presenter browseObjectsInMemoryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		self fail ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseMaglevFinalizerRegistryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'MagLev Finalizer Registry')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseSelectedConstantOpensBrowserWorkflow [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' nil nil nil 'Invoice' 'Accounting::Invoice').
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	self assert: presenter browseSelectedConstantClass.
	self assert: presenter lastBrowserClassName equals: 'Accounting::Invoice'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesBrowseSelectedAutoloadUsesOwningConstantMirror [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('InvoiceAlias' nil nil 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')) ].
				^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' false).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter browseSelectedConstantClass.
	self assert: presenter lastBrowserClassName equals: 'Accounting::Invoice'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenSelectedAutoloadNamespaceUsesOwningConstantMirror [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls nameSpace: 1')
			ifTrue: [ self fail ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')) ].
				^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter openSelectedConstantNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenNamespaceMirrorAddsAndSelectsNewRow [
	| mockSession namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	namespace instVarNamed: 'constantEntries' put: #().
	namespace instVarNamed: 'autoloadEntries' put: #().
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: (namespacesPresenter openNamespaceMirror: namespace).
	self assert: fakeNamespaceTable items size equals: 1.
	self assert: fakeNamespaceTable items first == namespace.
	self assert: fakeNamespaceTable selectedItem == namespace
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenNamespaceMirrorSelectsExistingEquivalentRow [
	| mockSession existingRow incomingRow fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	existingRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	existingRow instVarNamed: 'constantEntries' put: #().
	existingRow instVarNamed: 'autoloadEntries' put: #().
	incomingRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { existingRow }.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: (namespacesPresenter openNamespaceMirror: incomingRow).
	self assert: fakeNamespaceTable items size equals: 1.
	self assert: fakeNamespaceTable items first == incomingRow.
	self assert: fakeNamespaceTable selectedItem == incomingRow
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenNamespaceMirrorReplacesExistingRowToUseFreshDetails [
	| mockSession existingRow incomingRow fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	existingRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'System myUserProfile symbolList at: 1'
		symbolListIndex: 1
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	existingRow
		instVarNamed: 'constantEntries'
		put: #(#('StaleThing' nil nil nil nil nil)).
	existingRow
		instVarNamed: 'autoloadEntries'
		put: #().
	incomingRow := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	incomingRow
		instVarNamed: 'constantEntries'
		put: #(#('FreshThing' nil nil nil nil nil)).
	incomingRow
		instVarNamed: 'autoloadEntries'
		put: #().
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { existingRow }.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: (namespacesPresenter openNamespaceMirror: incomingRow).
	self assert: fakeNamespaceTable items first == incomingRow.
	self assert: fakeNamespaceTable selectedItem == incomingRow.
	self assert: fakeConstantsTable items size equals: 1.
	self assert: fakeConstantsTable items first name equals: 'FreshThing'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenNamespaceMirrorClearsDetailSelectionsWhenChangingNamespace [
	| mockSession oldNamespace newNamespace oldConstant oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	oldNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 'Object' 'Object' 'RubyNameSpace' 'Object').
	newNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Accounting nameSpace: 1'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Accounting').
	newNamespace
		instVarNamed: 'constantEntries'
		put: #(#('InvoiceAlias' 8101 'Class' nil 'Invoice' 'Accounting::Invoice')).
	newNamespace
		instVarNamed: 'autoloadEntries'
		put: #(#('InvoiceAlias' 'lib/invoice.rb' true 9191)).
	oldConstant := GbsRemoteConstantMirror
		on: oldNamespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Object::Invoice').
	oldAutoload := GbsRemoteAutoloadMirror
		on: oldNamespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable items: { oldNamespace }.
	fakeNamespaceTable selectedItem: oldNamespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: oldConstant.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: oldAutoload.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	namespacesPresenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: (namespacesPresenter openNamespaceMirror: newNamespace).
	self assert: fakeNamespaceTable selectedItem oop equals: 8001.
	self assert: fakeConstantsTable items size equals: 1.
	self assert: fakeAutoloadTable items size equals: 1.
	self assert: fakeConstantsTable selectedItem isNil.
	self assert: fakeAutoloadTable selectedItem isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenSelectedAutoloadNamespaceUsesOwnerNamespaceWithoutNamespaceRow [
	| mockSession presenter namespace autoload fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls nameSpace: 1')
			ifTrue: [ self fail ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')) ].
				^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter openSelectedConstantNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenSelectedConstantNamespaceUsesTargetNamespaceMirror [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls nameSpace: 1')
			ifTrue: [ self fail ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('Accounting' 7101 'Class' nil 'Accounting' 'Accounting').
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	self assert: presenter openSelectedConstantNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenSelectedConstantNamespaceFallsBackToSelectedNamespaceForPendingAutoload [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #() ].
				^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' false 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter openSelectedConstantNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenSelectedConstantNamespaceUsesSelectedNamespaceWhenNoConstantSelected [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.

	self assert: presenter openSelectedConstantNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenParentNamespaceUsesParentNamespaceMirror [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls ifNil: [ nil ] ifNotNil: [ cls nameSpace: 1 ]')
			ifTrue: [
				self assert: (script includesSubstring: '_objectForOop: 8101').
				^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8101)'
		symbolListIndex: nil
		metadata: #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.

	self assert: presenter openParentNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenParentNamespaceUsesSelectedAutoloadTargetNamespace [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '_objectForOop: 8101')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')) ].
				^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.

	self assert: presenter openParentNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenParentNamespaceUsesSelectedConstantTargetNamespace [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '_objectForOop: 8101')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.

	self assert: presenter openParentNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenTopLevelNamespaceUsesSessionTopLevelMirror [
	| mockSession presenter fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.

	self assert: presenter openTopLevelNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceInformsWhenMissing [
	| mockSession presenter fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | ^ nil ].
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: 'Accounting::Missing'.

	self deny: presenter openPromptedNamespace.
	self assert: presenter lastInfoMessage equals: 'Namespace Accounting::Missing was not found.'.
	self assert: presenter lastOpenedNamespaceMirror isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceUsesFullNameLookup [
	| mockSession presenter fakeNamespaceTable sawLookup |
	mockSession := MockGbsSession new.
	sawLookup := false.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '''Accounting::Invoice''')
			ifTrue: [ sawLookup := true ].
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: 'Accounting::Invoice'.

	self assert: presenter openPromptedNamespace.
	self assert: sawLookup.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesDotDotChildPath [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '''Accounting::Invoice''').
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
	currentNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8201)'
		symbolListIndex: nil
		metadata: #(8201 'Accounting::Billing' 'Accounting::Billing' 'RubyNameSpace' 'Module').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: currentNamespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: '..::Invoice'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesDotFromSelectedAutoloadTargetNamespace [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '''Accounting::Invoice''')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('InvoiceAlias' 7101 'Class' 'lib/invoice.rb' 'Invoice' 'Accounting::Invoice')) ].
				^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	namespace := mockSession topLevelNamespaceMirror.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('InvoiceAlias' 'lib/invoice.rb' true 9191).
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeAutoloadTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeAutoloadTable selectedItem: autoload.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'autoloadTable' put: fakeAutoloadTable.
	presenter enqueueRequestAnswer: '.'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesDotFromSelectedConstantTargetNamespace [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '''Accounting::Invoice''')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: '_objectForOop: 7101')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	constant := GbsRemoteConstantMirror
		on: namespace
		metadata: #('InvoiceAlias' 7101 'Class' nil 'Invoice' 'Accounting::Invoice').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	fakeConstantsTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeConstantsTable selectedItem: constant.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter instVarNamed: 'constantsTable' put: fakeConstantsTable.
	presenter enqueueRequestAnswer: '.'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesDotToCurrentNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '''Accounting::Invoice''').
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
	currentNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8101)'
		symbolListIndex: nil
		metadata: #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: currentNamespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: '.'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesRelativeNameFromSelectedNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '''Accounting::Invoice''').
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
	currentNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8001)'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: currentNamespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: 'Invoice'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 8101
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesOpenPromptedNamespaceResolvesDotDotToTopLevelNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'findTokens: ''::''')
			ifTrue: [ self fail ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 'Object' 'Object' 'RubyNameSpace' 'Object') ].
		self fail ].
	currentNamespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8001)'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: currentNamespace.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	presenter enqueueRequestAnswer: '..'.

	self assert: presenter openPromptedNamespace.
	self assert: presenter lastOpenedNamespaceMirror notNil.
	self assert: presenter lastOpenedNamespaceMirror oop equals: 7001
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesRefreshRuntimeInfoIncludesNamespacePathAndParent [
	| mockSession fakeText namespace fakeNamespaceTable |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key') ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: (Object _objectForOop: 8101)'
		symbolListIndex: nil
		metadata: #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class').
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeNamespaceTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeNamespaceTable selectedItem: namespace.
	namespacesPresenter instVarNamed: 'session' put: mockSession.
	namespacesPresenter instVarNamed: 'runtimeText' put: fakeText.
	namespacesPresenter instVarNamed: 'namespacesTable' put: fakeNamespaceTable.
	namespacesPresenter instVarNamed: 'constantsTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	namespacesPresenter instVarNamed: 'autoloadTable' put: GbxFakeTablePresenterForRemoteDebugger new.

	namespacesPresenter refreshRuntimeInfo.

	self assert: (fakeText text includesSubstring: 'Namespace Path: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Selected Namespace Source: Selected Namespace Row').
	self assert: (fakeText text includesSubstring: 'Lookup Base Source: Selected Namespace').
	self assert: (fakeText text includesSubstring: 'Lookup Base Namespace: Accounting::Invoice').
	self assert: (fakeText text includesSubstring: 'Lookup Base Parent: Accounting').
	self assert: (fakeText text includesSubstring: 'Parent Namespace: Accounting')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesLiteralStringEscapesEmbeddedQuote [
	self
		assert: (securityPoliciesPresenter literalString: 'Data''Curator')
		equals: '''Data''''Curator'''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesParseRowsPadsMissingColumns [
	| rows row |
	rows := securityPoliciesPresenter
		parseRows: 'Current', Character tab asString, 'Default', Character tab asString, 'DataCuratorObjectSecurityPolicy'
		expectedColumns: 8.
	row := rows first.

	self assert: row size equals: 8.
	self assert: (row at: 1) equals: 'Current'.
	self assert: (row at: 2) equals: 'Default'.
	self assert: (row at: 3) equals: 'DataCuratorObjectSecurityPolicy'.
	self assert: (row at: 8) equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesFullReportTextIncludesPoliciesGroupsAndMembers [
	| fakePolicies fakeGroups fakeMembers report |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA' 'DataCurator' 'write' 'read' '2' 'No') }.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeMembers := GbxFakeListPresenterForBrowser new.
	fakeMembers items: #('DataCurator' 'GcUser').

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	report := securityPoliciesPresenter fullReportText.

	self assert: (report includesSubstring: '=== Policies ===').
	self assert: (report includesSubstring: 'PolicyA').
	self assert: (report includesSubstring: '=== Groups ===').
	self assert: (report includesSubstring: 'DataCuratorGroup').
	self assert: (report includesSubstring: '=== Members ===').
	self assert: (report includesSubstring: 'GcUser')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesMembersScriptIncludesSelectedGroupLiteral [
	| script |
	script := securityPoliciesPresenter
		membersScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRefreshSelectedPolicyMembersUsesSelectedGroup [
	| mockSession fakePolicies fakeGroups fakeMembers lastScript |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	lastScript := ''.
	mockSession stubs at: #evaluate put: [ :script |
		lastScript := script.
		'DataCurator', String lf, 'GcUser' ].

	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA') }.
	fakePolicies selectedItem: fakePolicies items first.

	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeGroups selectedItem: fakeGroups items first.

	fakeMembers := GbxFakeListPresenterForBrowser new.

	securityPoliciesPresenter instVarNamed: 'session' put: mockSession.
	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	securityPoliciesPresenter refreshSelectedPolicyMembers.

	self assert: (lastScript includesSubstring: '''DataCuratorGroup''').
	self assert: fakeMembers items size equals: 2.
	self assert: fakeMembers items first equals: 'DataCurator'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesAddGroupScriptEscapesInputsAndAddsMapping [
	| script |
	script := securityPoliciesPresenter
		addGroupScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'
		accessString: 'read'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'Group already exists in policy').
	self assert: (script includesSubstring: 'groups at: ').
	self assert: (script includesSubstring: ' put: ')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRemoveGroupScriptEscapesInputsAndRemovesMapping [
	| script |
	script := securityPoliciesPresenter
		removeGroupScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'removeKey:').
	self assert: (script includesSubstring: 'Group not found in policy')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesPolicyOopScriptEscapesPolicyName [
	| script |
	script := securityPoliciesPresenter policyOopScriptForPolicyName: 'Policy''A'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: 'Reflection oopOf: policy')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesGroupOopScriptEscapesPolicyAndGroupNames [
	| script |
	script := securityPoliciesPresenter
		groupOopScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'Reflection oopOf: grp')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesMemberOopScriptEscapesAllNames [
	| script |
	script := securityPoliciesPresenter
		memberOopScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'
		memberName: 'User''C'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: '''User''''C''').
	self assert: (script includesSubstring: 'Reflection oopOf: member')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesPolicyReportTextUsesSelectedPolicyOnly [
	| fakePolicies report |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: {
		#('Current' 'Default' 'PolicyA' 'OwnerA' 'write' 'read' '1' 'No').
		#('' '' 'PolicyB' 'OwnerB' 'read' 'read' '2' 'Yes') }.
	fakePolicies selectedItem: fakePolicies items second.

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: (GbxFakeTablePresenterForRemoteDebugger new).
	securityPoliciesPresenter instVarNamed: 'membersList' put: (GbxFakeListPresenterForBrowser new).

	report := securityPoliciesPresenter policyReportText.
	self assert: (report includesSubstring: 'PolicyB').
	self deny: (report includesSubstring: 'PolicyA')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesGroupAndMemberReportsIncludeContextHeaders [
	| fakePolicies fakeGroups fakeMembers groupReport memberReport |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA' 'OwnerA' 'write' 'read' '1' 'No') }.
	fakePolicies selectedItem: fakePolicies items first.

	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeGroups selectedItem: fakeGroups items first.

	fakeMembers := GbxFakeListPresenterForBrowser new.
	fakeMembers items: #('DataCurator' 'GcUser').

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	groupReport := securityPoliciesPresenter groupReportText.
	memberReport := securityPoliciesPresenter memberReportText.

	self assert: (groupReport includesSubstring: 'Policy: PolicyA').
	self assert: (groupReport includesSubstring: 'DataCuratorGroup').
	self assert: (memberReport includesSubstring: 'Policy: PolicyA').
	self assert: (memberReport includesSubstring: 'Group: DataCuratorGroup').
	self assert: (memberReport includesSubstring: 'GcUser')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyOwnerAccessScriptEscapesInputs [
	| script |
	script := securityPoliciesPresenter
		setPolicyOwnerAccessScriptForPolicyName: 'Policy''A'
		accessString: 'write'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''write''').
	self assert: (script includesSubstring: 'ownerAuthorization:').
	self assert: (script includesSubstring: 'ownerAccess:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyWorldAccessScriptEscapesInputs [
	| script |
	script := securityPoliciesPresenter
		setPolicyWorldAccessScriptForPolicyName: 'Policy''A'
		accessString: 'read'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''read''').
	self assert: (script includesSubstring: 'worldAuthorization:').
	self assert: (script includesSubstring: 'worldAccess:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyTrackReadsScriptWritesBooleanLiteral [
	| script |
	script := securityPoliciesPresenter
		setPolicyTrackReadsScriptForPolicyName: 'Policy''A'
		trackReads: true.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: 'trackReads: true').
	self assert: (script includesSubstring: 'isTrackingReads:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesCapabilityPredicatesTrackSelectionState [
	| fakePolicies fakeGroups fakeMembers |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeMembers := GbxFakeListPresenterForBrowser new.

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	self deny: securityPoliciesPresenter canOperateOnSelectedPolicy.
	self deny: securityPoliciesPresenter canOperateOnSelectedGroup.
	self deny: securityPoliciesPresenter canOperateOnSelectedMember.

	fakePolicies items: { #('Current' 'Default' 'PolicyA') }.
	fakePolicies selectedItem: fakePolicies items first.
	self assert: securityPoliciesPresenter canOperateOnSelectedPolicy.
	self deny: securityPoliciesPresenter canOperateOnSelectedGroup.

	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeGroups selectedItem: fakeGroups items first.
	self assert: securityPoliciesPresenter canOperateOnSelectedGroup.
	self deny: securityPoliciesPresenter canOperateOnSelectedMember.

	fakeMembers items: #('DataCurator').
	fakeMembers selectedItem: 'DataCurator'.
	self assert: securityPoliciesPresenter canOperateOnSelectedMember
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRefreshAllPreservesSelectedPolicyWhenStillPresent [
	| mockSession fakePolicies fakeGroups fakeMembers |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'allPolicies do:')
			ifTrue: [
				^ 'Current', Character tab asString, 'Default', Character tab asString, 'PolicyA', Character tab asString, 'OwnerA', Character tab asString, 'write', Character tab asString, 'read', Character tab asString, '1', Character tab asString, 'No', String lf,
					'', Character tab asString, '', Character tab asString, 'PolicyB', Character tab asString, 'OwnerB', Character tab asString, 'read', Character tab asString, 'read', Character tab asString, '2', Character tab asString, 'Yes' ].
		(script includesSubstring: '= ''PolicyA''')
			ifTrue: [ ^ 'GroupA', Character tab asString, 'write' ].
		(script includesSubstring: '= ''PolicyB''')
			ifTrue: [ ^ 'GroupB', Character tab asString, 'read' ].
		(script includesSubstring: 'GroupA')
			ifTrue: [ ^ 'UserA' ].
		(script includesSubstring: 'GroupB')
			ifTrue: [ ^ 'UserB' ].
		^ '' ].

	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA'). #('' '' 'PolicyB') }.
	fakePolicies selectedItem: fakePolicies items second.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeMembers := GbxFakeListPresenterForBrowser new.

	securityPoliciesPresenter instVarNamed: 'session' put: mockSession.
	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	securityPoliciesPresenter refreshAll.

	self assert: (fakePolicies selectedItem at: 3) equals: 'PolicyB'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRefreshGroupsAndMembersPreservesSelections [
	| mockSession fakePolicies fakeGroups fakeMembers |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: '= ''PolicyA''')
			ifTrue: [
				(script includesSubstring: 'GroupA')
					ifTrue: [ ^ 'User1', String lf, 'User2' ].
				(script includesSubstring: 'GroupB')
					ifTrue: [ ^ 'UserB1', String lf, 'UserB2' ].
				^ 'GroupA', Character tab asString, 'write', String lf,
					'GroupB', Character tab asString, 'read' ].
		^ '' ].

	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA') }.
	fakePolicies selectedItem: fakePolicies items first.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('GroupA' 'write'). #('GroupB' 'read') }.
	fakeGroups selectedItem: fakeGroups items second.
	fakeMembers := GbxFakeListPresenterForBrowser new.
	fakeMembers items: #('UserB1' 'UserB2').
	fakeMembers selectedItem: 'UserB2'.

	securityPoliciesPresenter instVarNamed: 'session' put: mockSession.
	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	securityPoliciesPresenter refreshGroupsAndMembersForPolicyName: 'PolicyA'.

	self assert: (fakeGroups selectedItem at: 1) equals: 'GroupB'.
	self assert: fakeMembers selectedItem equals: 'UserB2'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserLoadOptionsFromConfigurationAppliesPostConnectAction [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectVerification put: false.
	cfg valueAt: #removeInvalidConnectors put: true.
	cfg valueAt: #connectorConnectionState put: 'disconnected'.
	cfg valueAt: #postConnectAction put: 'forwarder'.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter loadOptionsFromConfiguration.

	self deny: verify state.
	self assert: remove state.
	self deny: connected state.
	self assert: disconnected state.
	self assert: fwd state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: cfwd state.
	self deny: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserLoadOptionsDefaultsPostConnectActionToNone [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectVerification put: true.
	cfg valueAt: #removeInvalidConnectors put: true.
	cfg valueAt: #connectorConnectionState put: 'connected'.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter loadOptionsFromConfiguration.

	self assert: none state.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'none'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSaveOptionsToConfigurationStoresCurrentValues [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	verify state: true.
	remove state: false.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: true.
	fwd state: false.
	cfwd state: false.
	none state: false.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter saveOptionsToConfiguration.

	self assert: (cfg valueAt: #connectVerification ifAbsent: nil) equals: true.
	self assert: (cfg valueAt: #removeInvalidConnectors ifAbsent: nil) equals: false.
	self assert: (cfg valueAt: #connectorConnectionState ifAbsent: nil) equals: 'disconnected'.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'updateGS'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserApplyConnectionStateMapsDisconnectedSelection [
	| connected disconnected |
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.

	connectorBrowserPresenter applyConnectionState: 'disconnected'.

	self deny: connected state.
	self assert: disconnected state.
	self assert: connectorBrowserPresenter selectedConnectionState equals: 'disconnected'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserFilteredConnectorPairsHidesSessionRowsWhenDisconnected [
	| connected disconnected pairs filtered |
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	disconnected state: true.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.

	pairs := { #('Array' 'OArray'). #('String' 'OByteString') }.
	filtered := connectorBrowserPresenter
		filteredConnectorPairs: pairs
		forGroupLabel: 'Session connectors - ''DataCurator'' on ''gs64stone'''.

	self assert: filtered equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserOptionSelectionChangedSavesAndRefreshes [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none fakeGroupList fakeTable |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	verify state: true.
	remove state: false.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: false.
	fwd state: true.
	cfwd state: false.
	none state: false.

	fakeGroupList := GbxFakeListPresenterForBrowser new.
	fakeGroupList selectedItem: 'Session connectors - ''DataCurator'' on ''gs64stone'''.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable items: { #('sentinel') }.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
	connectorBrowserPresenter instVarNamed: 'groupItems' put: { fakeGroupList selectedItem }.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	connectorBrowserPresenter optionSelectionChanged.

	self assert: (cfg valueAt: #connectVerification ifAbsent: nil) equals: true.
	self assert: (cfg valueAt: #removeInvalidConnectors ifAbsent: nil) equals: false.
	self assert: (cfg valueAt: #connectorConnectionState ifAbsent: nil) equals: 'disconnected'.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'forwarder'.
	self assert: fakeTable items equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserApplySettingsForRowUsesRowDefaultsNotGlobalState [
	| cfg connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectorConnectionState put: 'disconnected'.
	cfg valueAt: #postConnectAction put: 'forwarder'.
	GbsConfiguration current: cfg.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter applySettingsForConnectorRow: #('Fast' 'ByteArray' 'ByteArray').

	self assert: connected state.
	self deny: disconnected state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserAppliesDifferentSavedStatePerConnectorRow [
	| cfg connected disconnected updateSt updateGs fwd cfwd none fakeTable rowA rowB |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	fakeTable selectedItem: rowA.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: true.
	fwd state: false.
	cfwd state: false.
	none state: false.
	connectorBrowserPresenter saveSettingsFromOptionStateForSelectedConnectors.

	fakeTable selectedItem: rowB.
	connected state: true.
	disconnected state: false.
	updateSt state: false.
	updateGs state: false.
	fwd state: false.
	cfwd state: false.
	none state: true.
	connectorBrowserPresenter saveSettingsFromOptionStateForSelectedConnectors.

	connectorBrowserPresenter applySettingsForConnectorRow: rowA.
	self deny: connected state.
	self assert: disconnected state.
	self deny: updateSt state.
	self assert: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self deny: none state.

	connectorBrowserPresenter applySettingsForConnectorRow: rowB.
	self assert: connected state.
	self deny: disconnected state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserConnectDisconnectUpdatesSessionManagerState [
	| cfg connected disconnected row |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	row := #('Fast' 'ByteArray' 'ByteArray').

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: (GbxFakeTablePresenterForRemoteDebugger new).
	(connectorBrowserPresenter instVarNamed: 'connectorTable') selectedItem: row.
	connectorBrowserPresenter instVarNamed: 'session' put: (MockGbsSession new).

	connectorBrowserPresenter connectorDisconnectSelected.
	self deny: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'unknown-user@unknown-stone').

	connectorBrowserPresenter connectorConnectSelected.
	self assert: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'unknown-user@unknown-stone')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSelectedConnectorRowsFallsBackToSelectedItem [
	| fakeTable row |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	fakeTable selectedItem: row.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	self assert: connectorBrowserPresenter selectedConnectorRows size equals: 1.
	self assert: connectorBrowserPresenter hasSelectedConnectors.
	self assert: connectorBrowserPresenter hasSingleSelectedConnector.
	self assert: connectorBrowserPresenter selectedConnectorRows first equals: row
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSelectedConnectorRowsUsesMultiSelectionWhenPresent [
	| fakeTable rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	self assert: connectorBrowserPresenter selectedConnectorRows size equals: 2.
	self assert: connectorBrowserPresenter hasSelectedConnectors.
	self deny: connectorBrowserPresenter hasSingleSelectedConnector
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCanInitializeSelectedGroupOnlyForGlobal [
	| fakeGroupList globalGroup sessionGroup |
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	globalGroup := GbsConnectorGroup globalOnManagerClass: GbsSessionManager.
	sessionGroup := GbsConnectorGroup session: (MockGbsSession new) managerClass: GbsSessionManager.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.

	fakeGroupList selectedItem: globalGroup.
	self assert: connectorBrowserPresenter canInitializeSelectedGroup.

	fakeGroupList selectedItem: sessionGroup.
	self deny: connectorBrowserPresenter canInitializeSelectedGroup
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserUpdateControlsDisablesWhenMultiSelected [
	| fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter updateConnectorControlsFromSelection.

	self deny: connected enabled.
	self deny: disconnected enabled.
	self deny: updateSt enabled.
	self deny: updateGs enabled.
	self deny: forwarder enabled.
	self deny: clientForwarder enabled.
	self deny: none enabled.
	self deny: connected state.
	self deny: disconnected state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserUpdateControlsEnablesForSingleSelection [
	| fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none row |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	fakeTable selectedItems: { row }.
	fakeTable selectedItem: row.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'session' put: (MockGbsSession new).
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter updateConnectorControlsFromSelection.

	self assert: connected enabled.
	self assert: disconnected enabled.
	self assert: updateSt enabled.
	self assert: updateGs enabled.
	self assert: forwarder enabled.
	self assert: clientForwarder enabled.
	self assert: none enabled
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCapabilityPredicatesTrackSelectionCount [
	| fakeTable rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	fakeTable selectedItems: #().
	fakeTable selectedItem: nil.
	self deny: connectorBrowserPresenter canInspectSelectedConnector.
	self deny: connectorBrowserPresenter canRemoveSelectedConnectors.
	self deny: connectorBrowserPresenter canSetConnectorClassMapping.

	fakeTable selectedItems: { rowA }.
	fakeTable selectedItem: rowA.
	self assert: connectorBrowserPresenter canInspectSelectedConnector.
	self assert: connectorBrowserPresenter canRemoveSelectedConnectors.
	self assert: connectorBrowserPresenter canSetConnectorClassMapping.

	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.
	self deny: connectorBrowserPresenter canInspectSelectedConnector.
	self assert: connectorBrowserPresenter canRemoveSelectedConnectors.
	self deny: connectorBrowserPresenter canSetConnectorClassMapping
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCanAddRequiresSelectedGroup [
	| fakeGroupList |
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.

	fakeGroupList selectedItem: nil.
	self deny: connectorBrowserPresenter canAddConnector.

	fakeGroupList selectedItem: (GbsConnectorGroup globalOnManagerClass: GbsSessionManager).
	self assert: connectorBrowserPresenter canAddConnector
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserAddRemoveAreReflectedInConnectorPaneAfterRefresh [
	| globalGroup fakeTable clientName serverName |
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	globalGroup := GbsSessionManager globalConnectorGroup.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	clientName := 'ABCConnectorTest'.
	serverName := 'DEFConnectorTest'.

	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self deny: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ]).

	GbsSessionManager addConnectorClient: clientName server: serverName.
	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self assert: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ]).

	GbsSessionManager removeConnectorClient: clientName server: serverName.
	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self deny: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserPostConnectActionPersistsAcrossUpdate [
	| cfg globalGroup fakeGroupList fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none verification selectedRow |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	GbsSessionManager addConnectorClient: 'PersistClient' server: 'PersistServer'.
	globalGroup := GbsSessionManager globalConnectorGroup.
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	fakeGroupList selectedItem: globalGroup.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	verification := GbxFakeTogglePresenter new.
	verification state: true.

	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
	connectorBrowserPresenter instVarNamed: 'groupItems' put: { globalGroup }.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verification.

	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	selectedRow := fakeTable items
		detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'PersistClient' ]
		ifNone: [ nil ].
	self assert: selectedRow notNil.
	fakeTable selectedItem: selectedRow.
	connectorBrowserPresenter postConnectActionChangedTo: 'forwarder'.
	self assert: forwarder state.

	connectorBrowserPresenter update.
	selectedRow := fakeTable items
		detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'PersistClient' ]
		ifNone: [ nil ].
	self assert: selectedRow notNil.
	fakeTable selectedItem: selectedRow.
	connectorBrowserPresenter applySettingsForConnectorRow: selectedRow.
	self assert: forwarder state.
	self deny: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserPostConnectActionPersistsAcrossReopen [
	| connectorObject presenter2 updateSt1 updateGs1 forwarder1 clientForwarder1 none1 connected1 disconnected1 updateSt2 updateGs2 forwarder2 clientForwarder2 none2 connected2 disconnected2 |
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	GbsSessionManager addConnectorClient: 'ReopenClient' server: 'ReopenServer'.
	GbsSessionManager
		setPostConnectAction: 'clientForwarder'
		forConnectorClient: 'ReopenClient'
		server: 'ReopenServer'.
	connectorObject := GbsSessionManager
		connectorObjectForClient: 'ReopenClient'
		server: 'ReopenServer'.

	updateSt1 := GbxFakeTogglePresenter new.
	updateGs1 := GbxFakeTogglePresenter new.
	forwarder1 := GbxFakeTogglePresenter new.
	clientForwarder1 := GbxFakeTogglePresenter new.
	none1 := GbxFakeTogglePresenter new.
	connected1 := GbxFakeTogglePresenter new.
	disconnected1 := GbxFakeTogglePresenter new.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected1.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected1.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt1.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs1.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder1.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder1.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none1.
	connectorBrowserPresenter applySettingsForConnectorRow: connectorObject.
	self assert: clientForwarder1 state.

	presenter2 := GbsConnectorBrowserPresenter new.
	updateSt2 := GbxFakeTogglePresenter new.
	updateGs2 := GbxFakeTogglePresenter new.
	forwarder2 := GbxFakeTogglePresenter new.
	clientForwarder2 := GbxFakeTogglePresenter new.
	none2 := GbxFakeTogglePresenter new.
	connected2 := GbxFakeTogglePresenter new.
	disconnected2 := GbxFakeTogglePresenter new.
	presenter2 instVarNamed: 'connectedRadio' put: connected2.
	presenter2 instVarNamed: 'disconnectedRadio' put: disconnected2.
	presenter2 instVarNamed: 'updateStRadio' put: updateSt2.
	presenter2 instVarNamed: 'updateGsRadio' put: updateGs2.
	presenter2 instVarNamed: 'forwarderRadio' put: forwarder2.
	presenter2 instVarNamed: 'clientForwarderRadio' put: clientForwarder2.
	presenter2 instVarNamed: 'noneRadio' put: none2.
	presenter2 applySettingsForConnectorRow: connectorObject.
	self assert: clientForwarder2 state.
	self deny: none2 state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserInvalidPostActionsDisableButtonsAndCoerceSelection [
	| cfg connected disconnected updateSt updateGs fwd cfwd none row settings |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsConnectorInvalidActionRegistry put: Dictionary new.
	GbsSessionManager
		setInvalidPostConnectActions: #('updateGS' 'forwarder')
		forConnectorClient: 'ByteArray'
		server: 'ByteArray'.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	settings := Dictionary new
		at: 'ByteArray->ByteArray' put: (Dictionary new at: #postConnectAction put: 'updateGS'; yourself);
		yourself.
	cfg valueAt: #connectorRowSettings put: settings.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter applySettingsForConnectorRow: row.

	self deny: updateGs enabled.
	self deny: fwd enabled.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoFetchGroupsForUserParsesCsv [
	| mockSession groups |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'DataCuratorGroup,Subscribers'.
	userInfoPresenter session: mockSession.

	groups := userInfoPresenter fetchGroupsForUser: 'DataCurator'.

	self assert: groups size equals: 2.
	self assert: (groups includes: 'DataCuratorGroup').
	self assert: (groups includes: 'Subscribers')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoRefreshInfoTextUpdatesTextPresenter [
	| mockSession fakeText |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'User: DataCurator', String lf, 'Class: UserProfile'.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.

	userInfoPresenter session: mockSession.
	userInfoPresenter userName: 'DataCurator'.
	userInfoPresenter infoText: ''.
	userInfoPresenter instVarNamed: 'textPresenter' put: fakeText.

	userInfoPresenter refreshInfoText.

	self assert: (fakeText text includesSubstring: 'User: DataCurator').
	self assert: (fakeText text includesSubstring: 'Class: UserProfile')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoEditPrivilegesPersistsUpdatedPrivilegesViaSessionExecute [
	| presenter mockSession executedScript updatedMap capturedUser capturedInitial |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	executedScript := ''.
	capturedUser := nil.
	capturedInitial := nil.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'privilegeNames do:')
			ifTrue: [ ^ 'SystemControl', Character tab asString, 'false' ].
		(script includesSubstring: 'String streamContents')
			ifTrue: [ ^ 'DataCuratorGroup' ].
		'User: DataCurator' ].
	mockSession stubs at: #execute put: [ :script | executedScript := script. true ].
	updatedMap := Dictionary new
		at: #SystemControl put: true;
		yourself.

	presenter
		userName: 'DataCurator';
		session: mockSession;
		infoText: '';
		privilegesEditorBlock: [ :user :initial :accept |
			capturedUser := user.
			capturedInitial := initial.
			accept value: updatedMap ].

	presenter editPrivileges.

	self assert: capturedUser equals: 'DataCurator'.
	self assert: ((capturedInitial at: #SystemControl ifAbsent: [ nil ]) == false).
	self assert: (executedScript includesSubstring: 'isSystemControl: true')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoInitializeSetsSafeDefaults [
	| presenter |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ]) new.
	self assert: (presenter instVarNamed: 'userName') equals: ''.
	self assert: (presenter instVarNamed: 'infoText') equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoInfoTextSetterNormalizesNilToEmptyString [
	| presenter |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ]) new.
	presenter infoText: nil.
	self assert: (presenter instVarNamed: 'infoText') equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoCanOperateOnUserInfoRequiresSessionAndUserName [
	| presenter mockSession |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.

	self deny: presenter canOperateOnUserInfo.
	presenter session: mockSession.
	self deny: presenter canOperateOnUserInfo.
	presenter userName: 'DataCurator'.
	self assert: presenter canOperateOnUserInfo
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoUpdateActionButtonsReflectsCapability [
	| presenter p s o mockSession |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	p := GbxFakeTogglePresenter new.
	s := GbxFakeTogglePresenter new.
	o := GbxFakeTogglePresenter new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.

	presenter instVarNamed: 'privilegesButton' put: p.
	presenter instVarNamed: 'symbolListButton' put: s.
	presenter instVarNamed: 'securityPoliciesButton' put: o.

	presenter userName: ''.
	presenter session: nil.
	presenter updateActionButtons.
	self deny: p enabled.
	self deny: s enabled.
	self deny: o enabled.

	presenter session: mockSession.
	presenter userName: 'DataCurator'.
	presenter updateActionButtons.
	self assert: p enabled.
	self assert: s enabled.
	self assert: o enabled
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListCapabilityPredicatesTrackSelectionState [
	| presenter fakeUsers fakeDicts fakeEntries |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeEntries := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.

	self deny: presenter canOperateOnSelectedUser.
	self deny: presenter canOperateOnSelectedDictionary.
	self deny: presenter canOperateOnSelectedEntry.

	fakeUsers selectedItem: 'DataCurator'.
	self assert: presenter canOperateOnSelectedUser.
	self deny: presenter canOperateOnSelectedDictionary.

	fakeDicts selectedItem: 'UserGlobals'.
	self assert: presenter canOperateOnSelectedDictionary.
	self deny: presenter canOperateOnSelectedEntry.

	fakeEntries selectedItem: 'MyKey'.
	self assert: presenter canOperateOnSelectedEntry
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListParsedStructuredPreviewMaterializesCollectionRows [
	| presenter result |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].

	result := presenter parsedStructuredPreviewFrom: 'collection', String lf, '1', Character tab asString, 'alpha', String lf, '2', Character tab asString, 'beta'.

	self assert: (result at: #kind) equals: 'collection'.
	self assert: (result at: #rows) equals: { { '1'. 'alpha' }. { '2'. 'beta' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListParsedStructuredPreviewMaterializesDictionaryRows [
	| presenter result |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].

	result := presenter parsedStructuredPreviewFrom: 'dictionary', String lf, 'users', Character tab asString, '#(''alice'' ''bob'')', String lf, 'count', Character tab asString, '2'.

	self assert: (result at: #kind) equals: 'dictionary'.
	self assert: (result at: #rows) equals: { { 'users'. '#(''alice'' ''bob'')' }. { 'count'. '2' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListParsedStructuredPreviewTreatsPlainStringsAsScalarRows [
	| presenter result |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].

	result := presenter parsedStructuredPreviewFrom: 'string', String lf, 'plain text value'.

	self assert: (result at: #kind) equals: 'string'.
	self assert: (result at: #rows) equals: { { 'Value'. 'plain text value' } }.
	self assert: (result at: #value) equals: 'plain text value'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListShowEntryForKeyPopulatesStructuredPreviewRows [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'entryKey := dict keys detect:')
			ifTrue: [ ^ 'dictionary', String lf, 'mediaAssets', Character tab asString, 'aDictionary()', String lf, 'users', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter showEntryForKey: 'OkzZuluSeasideState'.

	self assert: fakeSelection text equals: 'OkzZuluSeasideState'.
	self assert: fakeValue items equals: { { 'mediaAssets'. 'aDictionary()' }. { 'users'. 'aDictionary(...)' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListCanOperateOnSelectedPreviewRowRequiresStructuredSelection [
	| presenter fakeValue |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'mediaAssets'. 'aDictionary()' }.

	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).
	self assert: presenter canOperateOnSelectedPreviewRow.

	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'string'; yourself).
	self deny: presenter canOperateOnSelectedPreviewRow
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListStructuredPreviewForSelectedPreviewRowUsesSelectedRowLabel [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeValue result |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'path := #((''dictionary'' ''users''))')
			ifTrue: [ ^ 'collection', String lf, '1', Character tab asString, 'alice', String lf, '2', Character tab asString, 'bob' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).

	result := presenter structuredPreviewForSelectedPreviewRowInEntryKey: 'OkzZuluSeasideState'.

	self assert: (result at: #kind) equals: 'collection'.
	self assert: (result at: #rows) equals: { { '1'. 'alice' }. { '2'. 'bob' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorInspectSelectedEntryEvaluatesInspectBlockWithSelectedRow [
	| presenter fakeTable selected |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'table' put: fakeTable.
	presenter propertyAt: #inspectBlock put: [ :row | selected := row ].

	presenter inspectSelectedEntry.

	self assert: selected equals: { 'users'. 'aDictionary(...)' }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowseReferencersDelegatesReferencersBlockWithSelectedRow [
	| presenter fakeTable selected |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'table' put: fakeTable.
	presenter propertyAt: #referencersBlock put: [ :row | selected := row ].

	presenter browseReferencersForSelectedEntry.

	self assert: selected equals: { 'users'. 'aDictionary(...)' }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowsePromptedSessionStateKeyDelegatesParsedKey [
	| presenter requestedKey |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].

	presenter propertyAt: #requestInputBlock put: [ :prompt :default | '21' ].
	presenter propertyAt: #sessionStateBlock put: [ :key | requestedKey := key ].

	presenter browsePromptedSessionStateKey.

	self assert: requestedKey equals: 21
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter informed |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].

	presenter propertyAt: #requestInputBlock put: [ :prompt :default | 'abc' ].
	presenter propertyAt: #informBlock put: [ :message | informed := message ].
	presenter propertyAt: #sessionStateBlock put: [ :key | self fail ].

	presenter browsePromptedSessionStateKey.

	self assert: informed equals: 'Enter a numeric session state key.'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorMenuIncludesSessionStateActionWhenConfigured [
	| presenter |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	presenter propertyAt: #sessionStateBlock put: [ :key | ].

	self assert: presenter canBrowseSessionState
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorRowsSetterUpdatesExistingTable [
	| presenter fakeTable rows |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rows := { { 'mediaAssets'. 'aDictionary()' }. { 'users'. 'aDictionary(...)' } }.

	presenter instVarNamed: 'table' put: fakeTable.
	presenter rows: rows.

	self assert: fakeTable items equals: rows
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowseRubyLoadPathReportUsesConfiguredBlock [
	| presenter informed |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	presenter
		propertyAt: #loadPathReportBlock put: [ '$LOAD_PATH', String cr, String cr, 'lib' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseRubyLoadPathReport.

	self assert: informed equals: '$LOAD_PATH', String cr, String cr, 'lib'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowsePromptedSessionStateKeysReportDelegatesParsedKeys [
	| presenter informed keys |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	presenter
		propertyAt: #requestInputBlock put: [ :prompt :default | '19, 21' ];
		propertyAt: #sessionStateKeysReportBlock put: [ :parsedKeys |
			keys := parsedKeys.
			'Session State', String cr, String cr, 'Key 19' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browsePromptedSessionStateKeysReport.

	self assert: keys equals: #(19 21).
	self assert: informed equals: 'Session State', String cr, String cr, 'Key 19'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testStructuredValueInspectorBrowseObjectsInMemoryReportDelegatesPromptedRange [
	| presenter informed requestedRange answers |
	presenter := (Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsStructuredValueInspectorPresenter not loaded' ].
	answers := OrderedCollection with: '2' with: '5'.
	presenter
		propertyAt: #requestInputBlock put: [ :prompt :default | answers removeFirst ];
		propertyAt: #objectsInMemoryReportBlock put: [ :start :limit |
			requestedRange := { start. limit }.
			'Objects In Memory', String cr, String cr, 'oop=9201' ];
		propertyAt: #informBlock put: [ :message | informed := message ].

	presenter browseObjectsInMemoryReport.

	self assert: requestedRange equals: #(2 5).
	self assert: informed equals: 'Objects In Memory', String cr, String cr, 'oop=9201'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseReferencersForSelectedEntryUsesSessionFacadeAndOpensSingleResult [
	| presenter mockSession fakeUsers fakeDicts fakeEntries |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: '(Reflection oopOf: value) asString').
		self assert: (script includesSubstring: 'each asString = ''OkzZuluSeasideState''').
		'9001' ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		self assert: script equals: '((Object _objectForOop: 9001)) findReferencesInMemory asArray'.
		^ { GbsProxy oop: 9100 session: mockSession } ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.

	self assert: presenter browseReferencersForSelectedEntry.
	self assert: presenter lastOpenedOop equals: 9100
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseSessionStateAtKeyUsesSessionFacadeAndOpensInspector [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9201 session: mockSession ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: (presenter browseSessionStateAtKey: 21).
	self assert: presenter lastOpenedOop equals: 9201
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastOpenedOop isNil
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowsePromptedSessionStateKeyUsesPromptedValue [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9301 session: mockSession ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '21'.

	self assert: presenter browsePromptedSessionStateKey.
	self assert: presenter lastOpenedOop equals: 9301
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseRubyLoadPathReportUsesSessionRuntimeFacade [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseRubyLoadPathReport.
	self assert: (presenter lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (presenter lastInfoMessage includesSubstring: 'lib')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseStaleTypedWrapperLifecycleReportShowsStaleEntries [
	| presenter mockSession staleEntry |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
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
	mockSession stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseStaleTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (presenter lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '19, 21'.

	self assert: presenter browsePromptedSessionStateKeysReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| presenter mockSession |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: presenter browseObjectsInMemoryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListBrowseReferencersForSelectedPreviewValueUsesNestedPath [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeValue |
	presenter := (Smalltalk at: #TestableGbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'TestableGbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'path := #((''dictionary'' ''users''))').
		'9002' ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 9002)) findReferencesInMemory asArray'.
		^ { GbsProxy oop: 9200 session: mockSession } ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).

	self assert: presenter browseReferencersForSelectedPreviewValue.
	self assert: presenter lastOpenedOop equals: 9200
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListRefreshDictionariesPreservesSelectedDictionary [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'symbolList')
			ifTrue: [ ^ 'UserGlobals', Character tab asString, 'Globals', Character tab asString, 'Published' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'Globals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshDictionariesFor: 'DataCurator'.

	self assert: fakeDicts selectedItem equals: 'Globals'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListRefreshEntriesPreservesSelectedEntry [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'keys asSortedCollection')
			ifTrue: [ ^ 'KeyA', Character tab asString, '1', String lf, 'KeyB', Character tab asString, '2' ].
		'' ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'each asString = ''KeyB''')
			ifTrue: [ ^ 'dictionary', String lf, 'users', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'KeyB'.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshEntriesForDictionary: 'UserGlobals'.
	
	self assert: fakeEntries selectedItem equals: 'KeyB'.
	self assert: fakeSelection text equals: 'KeyB'.
	self assert: fakeValue items equals: { { 'users'. 'aDictionary(...)' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSymbolListRefreshUsersShowsSelectedDictionaryValuesOnOpen [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := (Smalltalk at: #GbsSymbolListBrowserPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsSymbolListBrowserPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		(script includesSubstring: 'users do:')
			ifTrue: [ ^ 'DataCurator', Character tab asString, 'SystemUser' ].
		(script includesSubstring: '1 to: sl size do:')
			ifTrue: [ ^ 'UserGlobals', Character tab asString, 'Globals' ].
		(script includesSubstring: 'keys asSortedCollection')
			ifTrue: [ ^ 'OkzZuluSeasideState', Character tab asString, 'aDictionary(...)', String lf, 'OtherEntry', Character tab asString, '123' ].
		'' ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		(script includesSubstring: 'each asString = ''OkzZuluSeasideState''')
			ifTrue: [ ^ 'dictionary', String lf, 'users', Character tab asString, 'aDictionary(...)', String lf, 'events', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'targetUserName' put: 'DataCurator'.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshUsers.

	self assert: fakeUsers selectedItem equals: 'DataCurator'.
	self assert: fakeDicts selectedItem equals: 'UserGlobals'.
	self assert: fakeEntries selectedItem equals: 'OkzZuluSeasideState'.
	self assert: fakeSelection text equals: 'OkzZuluSeasideState'.
	self assert: fakeValue items equals: { { 'users'. 'aDictionary(...)' }. { 'events'. 'aDictionary(...)' } }
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoSelectedInfoLinePredicatesTrackSelection [
	| presenter fakeList |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	fakeList := GbxFakeListPresenterForBrowser new.
	fakeList items: #('User: DataCurator' 'Class: UserProfile').
	presenter instVarNamed: 'textPresenter' put: fakeList.

	self deny: presenter hasSelectedInfoLine.
	fakeList selectedItem: 'Class: UserProfile'.
	self assert: presenter hasSelectedInfoLine.
	self assert: presenter selectedInfoLine equals: 'Class: UserProfile'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesCapabilityTransitionsClearDependentSelections [
	| fakePolicies fakeGroups fakeMembers |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeMembers := GbxFakeListPresenterForBrowser new.

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	fakePolicies items: { #('Current' 'Default' 'PolicyA') }.
	fakePolicies selectedItem: fakePolicies items first.
	fakeGroups items: { #('GroupA' 'read') }.
	fakeGroups selectedItem: fakeGroups items first.
	fakeMembers items: #('DataCurator').
	fakeMembers selectedItem: 'DataCurator'.

	self assert: securityPoliciesPresenter canOperateOnSelectedMember.
	fakeGroups selectedItem: nil.
	self deny: securityPoliciesPresenter canOperateOnSelectedGroup.
	self deny: securityPoliciesPresenter canOperateOnSelectedMember
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListFetchGroupsParsesCsvAndSetsUserField [
	| mockSession fakeGroupsList fakeTextField |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: 'DataCurator,GcUser'.

	fakeGroupsList := GbxFakeListPresenterForBrowser new.
	fakeTextField := GbxFakeTextPresenterForRemoteDebugger new.

	userListPresenter instVarNamed: 'session' put: mockSession.
	userListPresenter instVarNamed: 'groupList' put: fakeGroupsList.
	userListPresenter instVarNamed: 'userNameField' put: fakeTextField.

	userListPresenter fetchGroupsFor: 'DataCurator'.

	self assert: fakeGroupsList items size equals: 2.
	self assert: fakeTextField text equals: 'DataCurator'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListRefreshPopulatesUsersAndClearsGroups [
	| mockSession fakeUserList fakeGroupsList fakeTextField |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: 'DataCurator,GcUser,HostAgentUser'.

	fakeUserList := GbxFakeListPresenterForBrowser new.
	fakeGroupsList := GbxFakeListPresenterForBrowser new.
	fakeTextField := GbxFakeTextPresenterForRemoteDebugger new.

	userListPresenter instVarNamed: 'session' put: mockSession.
	userListPresenter instVarNamed: 'userList' put: fakeUserList.
	userListPresenter instVarNamed: 'groupList' put: fakeGroupsList.
	userListPresenter instVarNamed: 'userNameField' put: fakeTextField.

	userListPresenter refreshUserList.

	self assert: fakeUserList items size equals: 3.
	self assert: fakeGroupsList items isEmpty.
	self assert: fakeTextField text equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testCreateUserAuthFieldVisibilityFollowsLdapSelection [
	| gem unix ldap base filter |
	gem := GbxFakeTogglePresenter new.
	unix := GbxFakeTogglePresenter new.
	ldap := GbxFakeTogglePresenter new.
	base := GbxFakeTogglePresenter new.
	filter := GbxFakeTogglePresenter new.

	createUserPresenter instVarNamed: 'gemStoneAuthRadio' put: gem.
	createUserPresenter instVarNamed: 'unixAuthRadio' put: unix.
	createUserPresenter instVarNamed: 'ldapAuthRadio' put: ldap.
	createUserPresenter instVarNamed: 'baseDnField' put: base.
	createUserPresenter instVarNamed: 'filterDnField' put: filter.

	ldap state: false.
	createUserPresenter updateAuthFieldVisibility.
	self deny: base enabled.
	self deny: filter enabled.

	ldap state: true.
	createUserPresenter updateAuthFieldVisibility.
	self assert: base enabled.
	self assert: filter enabled
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListShowSelectedUserInfoUsesWindowPathWhenAvailable [
	| presenter mockSession |
	presenter := GbsTestableUserListPresenter new.
	mockSession := MockGbsSession new.
	presenter
		session: mockSession;
		forcedSelectedUser: 'DataCurator';
		fixedInfoText: 'User: DataCurator';
		openWindowResult: true;
		fallbackResult: true.

	presenter showSelectedUserInfo.

	self assert: presenter didOpenWindow.
	self deny: presenter didFallback.
	self assert: presenter openedUser equals: 'DataCurator'.
	self assert: presenter openedText equals: 'User: DataCurator'.
	self assert: presenter openedSession == mockSession
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListShowSelectedUserInfoFallsBackWhenWindowUnavailable [
	| presenter |
	presenter := GbsTestableUserListPresenter new.
	presenter
		forcedSelectedUser: 'DataCurator';
		fixedInfoText: 'User: DataCurator';
		openWindowResult: false;
		fallbackResult: true.

	presenter showSelectedUserInfo.

	self assert: presenter didOpenWindow.
	self assert: presenter didFallback
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoRefreshInfoTextIncludesPrivilegesSummary [
	| mockSession fakeText |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'privilegeNames do:')
			ifTrue: [ ^ 'SystemControl', Character tab asString, 'true' ].
		'User: DataCurator', String lf, 'Class: UserProfile' ].
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.

	userInfoPresenter session: mockSession.
	userInfoPresenter userName: 'DataCurator'.
	userInfoPresenter infoText: ''.
	userInfoPresenter instVarNamed: 'textPresenter' put: fakeText.

	userInfoPresenter refreshInfoText.

	self assert: (fakeText text includesSubstring: 'Privileges: SystemControl')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoAdditionalActionsDoNotRaiseWhenSessionPresent [
	| mockSession |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	userInfoPresenter
		session: mockSession;
		userName: 'DataCurator'.

	self shouldnt: [ userInfoPresenter editSymbolList ] raise: Error.
	self shouldnt: [ userInfoPresenter editSecurityPolicies ] raise: Error
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorGroupDescriptionUsesIvarBackedSessionParameters [
	| sessionObj params group description |
	sessionObj := GbsSession new.
	params := GbsSessionParameters new.
	params
		username: 'DataCurator';
		gemStoneName: 'gs64stone'.
	sessionObj instVarNamed: 'parameters' put: params.
	group := GbsConnectorGroup session: sessionObj managerClass: GbsSessionManager.

	description := group connectorGroupDescription.
	self assert: (description includesSubstring: 'DataCurator').
	self assert: (description includesSubstring: 'gs64stone')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserOptionSelectionChangedPreservesSelectedConnector [
	| cfg globalGroup fakeGroupList fakeTable verify remove connected disconnected updateSt updateGs forwarder clientForwarder none selectedRow |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.

	GbsSessionManager addConnectorClient: 'BClient' server: 'BServer'.
	GbsSessionManager addConnectorClient: 'AClient' server: 'AServer'.
	globalGroup := GbsSessionManager globalConnectorGroup.
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	verify state: true.

	fakeGroupList selectedItem: globalGroup.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
	connectorBrowserPresenter instVarNamed: 'groupItems' put: { globalGroup }.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	selectedRow := fakeTable items
		detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'BClient' ]
		ifNone: [ nil ].
	self assert: selectedRow notNil.
	fakeTable selectedItem: selectedRow.

	connectorBrowserPresenter optionSelectionChanged.

	self assert: (connectorBrowserPresenter rowClientName: fakeTable selectedItem) equals: 'BClient'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserConnectDisconnectPreserveSelectionAndReflectState [
	| previousCurrent mockSession params cfg globalGroup fakeGroupList fakeTable verify remove connected disconnected updateSt updateGs forwarder clientForwarder none selectedRow |
	previousCurrent := GbsSessionParameters currentSession.
	[
		mockSession := MockGbsSession new.
		(mockSession respondsTo: #isLoggedIn:) ifTrue: [ mockSession isLoggedIn: true ].
		params := GbsSessionParameters new.
		params
			username: 'DataCurator';
			gemStoneName: 'gs64stone'.
		mockSession instVarNamed: 'parameters' put: params.
		GbsSessionParameters currentSession: mockSession.

		cfg := GbsConfiguration new.
		GbsConfiguration current: cfg.
		Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
		Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
		Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.

		GbsSessionManager addConnectorClient: 'BClient' server: 'BServer'.
		GbsSessionManager addConnectorClient: 'AClient' server: 'AServer'.
		globalGroup := GbsSessionManager globalConnectorGroup.
		fakeGroupList := GbxFakeListPresenterForBrowser new.
		fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
		verify := GbxFakeTogglePresenter new.
		remove := GbxFakeTogglePresenter new.
		connected := GbxFakeTogglePresenter new.
		disconnected := GbxFakeTogglePresenter new.
		updateSt := GbxFakeTogglePresenter new.
		updateGs := GbxFakeTogglePresenter new.
		forwarder := GbxFakeTogglePresenter new.
		clientForwarder := GbxFakeTogglePresenter new.
		none := GbxFakeTogglePresenter new.
		verify state: true.

		fakeGroupList selectedItem: globalGroup.
		connectorBrowserPresenter instVarNamed: 'session' put: mockSession.
		connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
		connectorBrowserPresenter instVarNamed: 'groupItems' put: { globalGroup }.
		connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
		connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
		connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
		connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
		connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
		connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
		connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
		connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
		connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
		connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

		connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
		selectedRow := fakeTable items
			detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'BClient' ]
			ifNone: [ nil ].
		self assert: selectedRow notNil.
		fakeTable selectedItem: selectedRow.

		connectorBrowserPresenter connectorDisconnectSelected.
		self assert: (connectorBrowserPresenter rowClientName: fakeTable selectedItem) equals: 'BClient'.
		self assert: disconnected state.
		self deny: connected state.

		connectorBrowserPresenter connectorConnectSelected.
		self assert: (connectorBrowserPresenter rowClientName: fakeTable selectedItem) equals: 'BClient'.
		self assert: connected state.
		self deny: disconnected state.
	] ensure: [
		GbsSessionParameters currentSession: previousCurrent
	]
]
