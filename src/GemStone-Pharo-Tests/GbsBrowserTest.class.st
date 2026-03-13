Class {
	#name : 'GbsBrowserTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsBrowserTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession
]

{ #category : 'running' }
GbsBrowserTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsBrowserTest >> testFetchRemoteClasses [
	| session script rawData classes |
	
	session := GbsSessionParameters currentSession.
	(session isNil or: [ session isConnected not ]) ifTrue: [
		self skip: 'Requires an active GemStone session' ].
	
	script := '[
		| dict classNames stream |
		dict := System myUserProfile symbolList objectNamed: #Globals.
		classNames := dict keys select: [ :each | (dict at: each) isBehavior ].
		stream := WriteStream on: String new.
		classNames asSortedCollection do: [ :cls | stream nextPutAll: cls asString; lf ].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	self assert: rawData isNotNil.
	self deny: (rawData beginsWith: 'Error:').
	
	"1. Split the string"
	classes := rawData splitOn: Character lf.
	
	"2. CRITICAL FIX: Trim all invisible carriage returns/spaces from C-strings!!"
	classes := classes collect: [ :each | each trimBoth ].
	classes := classes reject: [ :each | each isEmpty ].
	
	"3. Print to your Remote Transcript so you can actually SEE the data!"
	Transcript show: 'Fetched ', classes size asString, ' classes from GemStone!'; cr.
	Transcript show: 'First 5 classes: ', (classes copyFrom: 1 to: 5) printString; cr.
	
	"4. Assertions"
	self assert: classes isNotEmpty description: 'No classes were found in Globals'.
	self assert: (classes includes: 'Association') description: 'Standard classes are missing!'.
]

{ #category : 'tests' }
GbsBrowserTest >> testAcceptTextDelegatesToCompileMethod [
	| browser |
	browser := TestableGbsBrowser new.
	browser enableCompileSpy.

	self assert: (browser acceptText: 'foo ^ 1') equals: #compiled.
	self assert: browser lastCompileSource equals: 'foo ^ 1'
]

{ #category : 'tests' }
GbsBrowserTest >> testCompileMethodCompilesSelectedClassAndProtocol [
	| browser session classes protocols meta capturedScript |
	browser := TestableGbsBrowser new.
	session := MockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script |
		capturedScript := script.
		'Success'
	].

	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	protocols := GbxFakeListPresenterForBrowser new.
	protocols selectedItem: 'testing'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'protocolsList' put: protocols.
	browser instVarNamed: 'metaCheckbox' put: meta.

	browser runSuperCompileMethod: 'foo ^ 1'.
	self assert: (capturedScript includesSubstring: 'objectNamed: #DemoClass').
	self assert: (capturedScript includesSubstring: 'compileMethod: source category: #''testing''').
	self assert: browser lastInfoMessage equals: 'Compiled successfully!'.
	self assert: browser lastProtocolSelected equals: 'testing'
]

{ #category : 'tests' }
GbsBrowserTest >> testGsDoItUsesSelectedTextOrWholeSource [
	| browser session text |
	browser := TestableGbsBrowser new.
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx | 'ok' ].

	text := GbxFakeTextPresenterForBrowser new.
	text
		text: '1 + 1';
		selectedText: '2 + 2'.

	browser session: session.
	browser instVarNamed: 'sourceText' put: text.

	self assert: browser gsDoIt
]

{ #category : 'tests' }
GbsBrowserTest >> testGsPrintItAppendsResult [
	| browser session text |
	browser := TestableGbsBrowser new.
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx | '42' ].

	text := GbxFakeTextPresenterForBrowser new.
	text text: '21+21'.

	browser session: session.
	browser instVarNamed: 'sourceText' put: text.

	self assert: browser gsPrintIt.
	self assert: (text text includesSubstring: '"42"')
]

{ #category : 'tests' }
GbsBrowserTest >> testQueryImplementorsUsesPromptAndOpensSingleResult [
	| browser |
	browser := TestableGbsBrowser new.
	browser enqueueRequestAnswer: 'initialize'.
	browser queryResults: #('Object>>initialize') forMode: 'implementors'.

	self assert: browser queryImplementors.
	self assert: browser lastQueriedSelector equals: 'initialize'.
	self assert: browser lastQueriedMode equals: 'implementors'.
	self assert: browser lastOpenedReference equals: 'Object>>initialize'
]

{ #category : 'tests' }
GbsBrowserTest >> testQueryHierarchySendersUsesHierarchyMode [
	| browser classes |
	browser := TestableGbsBrowser new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'Object'.
	browser instVarNamed: 'classesList' put: classes.
	browser enqueueRequestAnswer: 'size'.
	browser queryResults: #('Object>>size') forMode: 'hierarchySenders'.

	self assert: browser queryHierarchySenders.
	self assert: browser lastQueriedSelector equals: 'size'.
	self assert: browser lastQueriedMode equals: 'hierarchySenders'
]

{ #category : 'tests' }
GbsBrowserTest >> testQueryHierarchyImplementorsUsesHierarchyMode [
	| browser classes |
	browser := TestableGbsBrowser new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'Object'.
	browser instVarNamed: 'classesList' put: classes.
	browser enqueueRequestAnswer: 'size'.
	browser queryResults: #('Object>>size') forMode: 'hierarchyImplementors'.

	self assert: browser queryHierarchyImplementors.
	self assert: browser lastQueriedSelector equals: 'size'.
	self assert: browser lastQueriedMode equals: 'hierarchyImplementors'
]

{ #category : 'tests' }
GbsBrowserTest >> testQueryHierarchyRequiresSelectedClass [
	| browser |
	browser := TestableGbsBrowser new.
	browser enqueueRequestAnswer: 'size'.

	self deny: browser queryHierarchySenders.
	self assert: browser lastInfoMessage equals: 'Select a class first for hierarchy queries.'
]

{ #category : 'tests' }
GbsBrowserTest >> testOpenQueryResultsChoosesFromMultipleReferences [
	| browser |
	browser := TestableGbsBrowser new.
	browser enqueueChooseAnswer: 2.

	self assert: (browser openQueryResults: #('Object>>initialize' 'Behavior>>initialize')).
	self assert: browser lastOpenedReference equals: 'Behavior>>initialize'
]

{ #category : 'tests' }
GbsBrowserTest >> testQueryMethodsWithStringUsesOpenQueryResultsPath [
	| browser session capturedScript |
	browser := TestableGbsBrowser new.
	session := MockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script |
		capturedScript := script.
		'Object>>initialize', Character lf asString, 'Behavior>>initialize' ].
	browser session: session.
	browser enqueueRequestAnswer: 'init'.
	browser enqueueChooseAnswer: 1.

	self assert: browser queryMethodsWithString.
	self assert: (capturedScript includesSubstring: 'init').
	self assert: browser lastOpenedReference equals: 'Behavior>>initialize'
]
