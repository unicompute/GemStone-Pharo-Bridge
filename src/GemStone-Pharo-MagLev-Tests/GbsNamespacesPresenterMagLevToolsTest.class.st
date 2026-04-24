Class {
	#name : 'GbsNamespacesPresenterMagLevToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'namespacesPresenter'
	],
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'running' }
GbsNamespacesPresenterMagLevToolsTest >> setUp [
	super setUp.
	namespacesPresenter := GbsNamespacesPresenter new
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesParseRowsParsesTabSeparatedColumns [
	| rows |
	rows := namespacesPresenter parseRows: '1', Character tab asString, 'UserGlobals', Character tab asString, 'SymbolDictionary', String lf, '2', Character tab asString, 'Globals', Character tab asString, 'SymbolDictionary'.

	self assert: rows size equals: 2.
	self assert: (rows first at: 1) equals: '1'.
	self assert: (rows first at: 2) equals: 'UserGlobals'.
	self assert: (rows first at: 3) equals: 'SymbolDictionary'
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshUsesNamespaceMirrors [
	| mockSession fakeTable items |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesSynchronizesDetailsAndRuntime [
	| mockSession previousNamespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseNamespaceReferencesUsesScopedQueryResults [
	| presenter mockSession namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	presenter := TestableGbsNamespacesPresenter new.
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseNamespaceImplementorsUsesScopedQueryResults [
	| presenter mockSession namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	presenter := TestableGbsNamespacesPresenter new.
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesClearsStaleDetailsAndRuntimeContext [
	| mockSession selectedNamespace oldConstant oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsUsesNamespaceMirrors [
	| mockSession fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesPreservesSelectedNamespaceRow [
	| mockSession fakeTable selectedNamespace replacementNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesClearsStaleSelectedNamespaceRow [
	| mockSession fakeTable selectedNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesUsesAutoloadOwnerWhenNamespaceRowMissing [
	| mockSession fakeNamespaceTable fakeAutoloadTable ownerNamespace autoload |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshNamespacesUsesConstantOwnerWhenNamespaceRowMissing [
	| mockSession fakeNamespaceTable fakeConstantsTable ownerNamespace constant |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsPreservesSelectedAutoloadRow [
	| mockSession namespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsRestoresNamespaceRowFromSelectedAutoloadOwner [
	| mockSession namespace ownerRow autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsClearsStaleSelectedAutoloadRow [
	| mockSession namespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsPreservesSelectedConstantRow [
	| mockSession namespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsRestoresNamespaceRowFromSelectedConstantOwner [
	| mockSession namespace ownerRow oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsClearsStaleSelectedConstantRow [
	| mockSession namespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsDoesNotCarryAutoloadSelectionAcrossNamespaceChange [
	| mockSession oldNamespace newNamespace oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshSelectedNamespaceDetailsDoesNotCarryConstantSelectionAcrossNamespaceChange [
	| mockSession oldNamespace newNamespace oldConstant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoIncludesSelectedConstantTarget [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoUsesConstantTargetLabelForAutoloadBackedConstantSelection [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoUsesConstantOwnerLookupLabelWhenTargetIsUnavailable [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoUsesAutoloadOwnerLookupLabelWhenTargetIsUnavailable [
	| mockSession fakeText namespace autoload fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoNormalizesConstantSelectedInAutoloadTable [
	| mockSession fakeText namespace constant fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectSelectedAutoloadNormalizesConstantSelectedInAutoloadTable [
	| mockSession presenter namespace constant fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesHandleAutoloadSelectionChangedClearsConstantSelection [
	| mockSession fakeText namespace constant autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesHandleConstantSelectionChangedClearsAutoloadSelection [
	| mockSession fakeText namespace constant autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesHandleAutoloadSelectionChangedNormalizesAutoloadBackedConstantSelection [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesHandleConstantSelectionChangedNormalizesAutoloadMirrorSelection [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoIncludesLookupBaseWithoutSelectedNamespace [
	| mockSession fakeText namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoIncludesSelectedAutoloadDetails [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoDoesNotShowAutoloadDetailsForSelectedAutoloadBackedConstant [
	| mockSession fakeText namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoDoesNotShowConstantDetailsForSelectedLoadedAutoload [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoNormalizesAutoloadMirrorSelectedInConstantsTable [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoUsesAutoloadOwnerWhenNamespaceRowIsMissing [
	| mockSession fakeText namespace autoload fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoIncludesLoadingAutoloadState [
	| mockSession fakeText namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoUsesRubyRuntimeSurface [
	| mockSession fakeText |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRequireSelectedFileUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable lastScript |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRequireSelectedFileInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesLoadSelectedFileUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable lastScript |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesLoadSelectedFileInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesClearPersistentLoadedFeaturesUsesRubyRuntimeSurface [
	| mockSession presenter namespace fakeNamespaceTable fakeText clearCalls persistentFeatures |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRegisterAutoloadUsesSelectedConstantAndPromptedFile [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable lastScript |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRegisterAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRequireSelectedAutoloadUsesSelectedEntryFile [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable lastScript |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRequireSelectedAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable fakeText phase |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRemoveSelectedAutoloadUsesSelectedAutoloadEntry [
	| mockSession presenter namespace constant fakeNamespaceTable fakeAutoloadTable lastScript |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRemoveSelectedAutoloadInvalidatesAndRefreshesNamespaceDetails [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable fakeAutoloadTable phase |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectSelectedConstantOpensInspectorWorkflow [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectSelectedAutoloadOpensInspectorWorkflow [
	| mockSession presenter namespace autoload fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectMaglevFinalizerRegistryOpensInspectorWorkflow [
	| mockSession presenter registry |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectPromptedSessionStateKeyInformsWhenUnset [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectPromptedSessionStateKeyRejectsNonNumericInput [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter inspectPromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastOpenedOop isNil
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesInspectPromptedSessionStateKeyUsesSessionFacade [
	| mockSession presenter registry |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseTypedWrapperLifecycleReportUsesSessionFacade [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #typedWrapperLifecycleReportText put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing -> ServerThing' ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (presenter lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseTypedWrapperAutoloadReportUsesSessionRegistry [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseStaleTypedWrapperLifecycleReportShowsStaleEntries [
	| mockSession presenter staleEntry |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshStaleTypedWrappersUsesSessionRefresh [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #refreshStaleTypedWrapperClasses put: [ { GbsTypedProxy. Object } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter refreshStaleTypedWrappers.
	self assert: presenter lastInfoMessage equals: 'Refreshed 2 stale typed wrapper(s).'
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshAllTypedWrappersUsesSessionRefresh [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #refreshAllTypedWrapperClasses put: [ { GbsTypedProxy } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter refreshAllTypedWrappers.
	self assert: presenter lastInfoMessage equals: 'Refreshed 1 typed wrapper(s).'
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseWrapperActionChooserUsesSelectedWrapperAction [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #refreshAllTypedWrapperClasses put: [ { GbsTypedProxy } ].
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueChooseAnswer: 5.

	self assert: presenter browseWrapperActionChooser.
	self assert: presenter lastInfoMessage equals: 'Refreshed 1 typed wrapper(s).'
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseRubyLoadPathReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseNamedObjectCacheReportUsesSessionCacheText [
	| mockSession presenter cache |
	mockSession := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession namedObjectCache addAll: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseNamedObjectCacheReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (presenter lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesClearNamedObjectCacheClearsSessionCache [
	| mockSession presenter cache |
	mockSession := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession namedObjectCache addAll: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter clearNamedObjectCache.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: mockSession namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseSessionStateReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseNamespaceAutoloadRegistrationsReportUsesSelectedNamespace [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseRuntimeReportChooserUsesSelectedRuntimeAction [
	| mockSession presenter cache |
	mockSession := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession namedObjectCache addAll: cache.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseRuntimeReportChooserCanClearNamedObjectCache [
	| mockSession presenter cache |
	mockSession := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: mockSession).
	mockSession namedObjectCache addAll: cache.
	presenter := TestableGbsNamespacesPresenter new.
	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueChooseAnswer: 2.

	self assert: presenter browseRuntimeReportChooser.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: mockSession namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| mockSession presenter |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseSelectedConstantOpensBrowserWorkflow [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesBrowseSelectedAutoloadUsesOwningConstantMirror [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenSelectedAutoloadNamespaceUsesOwningConstantMirror [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenNamespaceMirrorAddsAndSelectsNewRow [
	| mockSession namespace fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenNamespaceMirrorSelectsExistingEquivalentRow [
	| mockSession existingRow incomingRow fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenNamespaceMirrorReplacesExistingRowToUseFreshDetails [
	| mockSession existingRow incomingRow fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenNamespaceMirrorClearsDetailSelectionsWhenChangingNamespace [
	| mockSession oldNamespace newNamespace oldConstant oldAutoload fakeNamespaceTable fakeConstantsTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenSelectedAutoloadNamespaceUsesOwnerNamespaceWithoutNamespaceRow [
	| mockSession presenter namespace autoload fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenSelectedConstantNamespaceUsesTargetNamespaceMirror [
	| mockSession presenter namespace constant fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenSelectedConstantNamespaceFallsBackToSelectedNamespaceForPendingAutoload [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenSelectedConstantNamespaceUsesSelectedNamespaceWhenNoConstantSelected [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenParentNamespaceUsesParentNamespaceMirror [
	| mockSession presenter namespace fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenParentNamespaceUsesSelectedAutoloadTargetNamespace [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenParentNamespaceUsesSelectedConstantTargetNamespace [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenTopLevelNamespaceUsesSessionTopLevelMirror [
	| mockSession presenter fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceInformsWhenMissing [
	| mockSession presenter fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceUsesFullNameLookup [
	| mockSession presenter fakeNamespaceTable sawLookup |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesDotDotChildPath [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesDotFromSelectedAutoloadTargetNamespace [
	| mockSession presenter namespace autoload fakeNamespaceTable fakeAutoloadTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesDotFromSelectedConstantTargetNamespace [
	| mockSession presenter namespace constant fakeNamespaceTable fakeConstantsTable |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesDotToCurrentNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesRelativeNameFromSelectedNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesOpenPromptedNamespaceResolvesDotDotToTopLevelNamespace [
	| mockSession presenter fakeNamespaceTable currentNamespace |
	mockSession := CoreMockGbsSession new.
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
GbsNamespacesPresenterMagLevToolsTest >> testNamespacesRefreshRuntimeInfoIncludesNamespacePathAndParent [
	| mockSession fakeText namespace fakeNamespaceTable |
	mockSession := CoreMockGbsSession new.
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
