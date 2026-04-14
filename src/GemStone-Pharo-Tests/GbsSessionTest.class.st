Class {
	#name : 'GbsSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsSessionTest >> setUp [
    super setUp.
    session := GbsSession new.
]

{ #category : 'running' }
GbsSessionTest >> testAbortTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciAbort put: 1.
	
	self assert: mockSession abortTransaction equals: true.
]

{ #category : 'running' }
GbsSessionTest >> testCommitTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.
	
	self assert: mockSession commitTransaction equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testCommitTransactionFailure [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 0.
	
	self deny: mockSession commitTransaction.
]

{ #category : 'running' }
GbsSessionTest >> testExecuteStringReturnsUnboxedObject [
	| mockSession result |
	mockSession := MockGbsSession new.
	
	"1. Force the mock into the instance variable so it isn't nil!"
	mockSession instVarNamed: 'serverInterface' put: mockSession.
	
	"2. Stub the FFI call to return 268 (which GbsSession checks for 'true')"
	mockSession stubs at: #apiGciExecute put: 268. 
	
	result := mockSession execute: '2 > 1'.
	
	self assert: result equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteSignalsErrorWhenNotLoggedIn [
	self
		should: [ session execute: '1 + 1' ]
		raise: GbsError
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteStringSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #execute put: [ :script |
		GbsError signal: 'MessageNotUnderstood: #foo' ].
		
	self 
		should: [ mockSession execute: 'Object foo' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'MessageNotUnderstood: #foo' ]
]

{ #category : 'tests' }
GbsSessionTest >> testFetchClassesInDictionary [
	| mockSession classNames |
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'Object,String,Array'.
	
	classNames := mockSession fetchRemoteClassNamesIn: 'UserGlobals'.
	
	self assert: (classNames isKindOf: Collection).
	self assert: classNames first equals: 'Object'.
]

{ #category : 'tests' }
GbsSessionTest >> testLoginFailureSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: false.
	mockSession stubs at: #gciErr put: [ :errStruct | errStruct message: 'Login failed: Invalid password' ].
		
	self 
		should: [ mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'wrongpassword' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'Login failed: Invalid password' ].
]

{ #category : 'tests' }
GbsSessionTest >> testLoginSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: true.

	mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'swordfish'.
	self assert: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testNamedForwarderAccessorsUseSessionForwarderFor [
	| mockSession globals published userClasses userGlobals mapping |
	mockSession := MockGbsSession new.
	mapping := Dictionary new
		at: '#Globals' put: 1001;
		at: '#Published' put: 1002;
		at: '#UserClasses' put: 1003;
		at: '#UserGlobals' put: 1004;
		yourself.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | | match |
		match := mapping keys
			detect: [ :each | script includesSubstring: each ]
			ifNone: [ nil ].
		match
			ifNil: [ nil ]
			ifNotNil: [ GbsProxy oop: (mapping at: match) session: mockSession ] ].

	globals := mockSession globals.
	published := mockSession published.
	userClasses := mockSession userClasses.
	userGlobals := mockSession userGlobals.

	self assert: globals oop equals: 1001.
	self assert: published oop equals: 1002.
	self assert: userClasses oop equals: 1003.
	self assert: userGlobals oop equals: 1004
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsDictionaryExpression [
	| script |
	script := session
		marshalArgumentToScript: (Dictionary new
			at: 'name' put: 'Tariq';
			at: 'amount' put: 100;
			yourself).

	self assert: (script includesSubstring: 'Dictionary new').
	self assert: (script includesSubstring: 'at: ''name'' put: ''Tariq''').
	self assert: (script includesSubstring: 'at: ''amount'' put: 100')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsIdentityDictionaryExpression [
	| script |
	script := session
		marshalArgumentToScript: (IdentityDictionary new
			at: #ticket put: 'vip';
			yourself).

	self assert: (script includesSubstring: 'IdentityDictionary new').
	self assert: (script includesSubstring: 'at: #ticket put: ''vip''')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsNestedCollectionExpression [
	| object script |
	object := OrderedCollection new
		add: (Association key: #name value: 'Tariq');
		add: #(1 2 3);
		yourself.
	script := session marshalArgumentToScript: object.

	self assert: (script includesSubstring: 'OrderedCollection new').
	self assert: (script includesSubstring: 'Association key: #name value: ''Tariq''').
	self assert: (script includesSubstring: 'Array new: 3')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsRepeatedBagExpression [
	| bag script |
	bag := Bag new.
	bag add: 'vip'.
	bag add: 'vip'.
	script := session marshalArgumentToScript: bag.

	self assert: (script includesSubstring: 'Bag new').
	self assert: (script includesSubstring: 'add: ''vip''; add: ''vip''')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptRejectsCyclicCollections [
	| object |
	object := OrderedCollection new.
	object add: object.

	self
		should: [ session marshalArgumentToScript: object ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsSortedCollectionExpression [
	| script |
	script := session
		marshalArgumentToScript: (SortedCollection new
			add: 3;
			add: 1;
			add: 2;
			yourself).

	self assert: (script includesSubstring: 'SortedCollection new').
	self assert: (script includesSubstring: 'add: 1').
	self assert: (script includesSubstring: 'add: 2').
	self assert: (script includesSubstring: 'add: 3')
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: 1.
	
	mockSession logout.
	self deny: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutClearsAttachedParameterState [
	| mockSession params |
	mockSession := MockGbsSession new.
	mockSession
		instVarNamed: 'isLoggedIn' put: true;
		sessionId: 77;
		sessionOop: 77.
	mockSession stubs at: #gciLogout put: nil.
	params := GbsSessionParameters new.
	params sessionId: 77.
	params class currentSession: mockSession.
	params class registerSession: params.
	mockSession parameters: params.

	mockSession logout.

	self deny: mockSession isLoggedIn.
	self assert: mockSession sessionId isNil.
	self assert: mockSession sessionOop isNil.
	self assert: params sessionId isNil.
	self assert: params class currentSession isNil.
	self deny: (params class allSessions includes: params)
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutTreatsNilFfiReturnAsSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: nil.

	mockSession logout.

	self deny: mockSession isLoggedIn
]

{ #category : 'tests' }
GbsSessionTest >> testPollingLifecycle [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciPollForSignal put: 0.
	
	mockSession startPolling.
	self deny: mockSession isPolling.
	
	mockSession stopPolling.
	self deny: mockSession isPolling.
]

{ #category : 'running' }
GbsSessionTest >> testResultForComplexObjectReturnsProxy [

  | result |
  "1000 is not a special tag, should result in a GbsProxy"
  result := session resultFor: 1000.
  self assert: ( result isKindOf: GbsProxy ).
  self assert: result oop equals: 1000.
  self assert: result session equals: session
]

{ #category : 'running' }
GbsSessionTest >> testResultForPrimitives [
  "Verify Tag mapping per GS64 3.7 Programming Guide"

  self assert: ( session resultFor: 20 ) isNil.
  self assert: ( session resultFor: 28 ).
  self deny: ( session resultFor: 12 ).
  self assert: ( session resultFor: 82 ) equals: 10.
  "$A (65): (65 << 3) + 6 = 526"
	self assert: ( session resultFor: 526 ) equals: $A
]

{ #category : 'tests' }
GbsSessionTest >> testSessionForwarderForSignalsWhenMissing [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObjectResult put: nil.

	self
		should: [ mockSession sessionForwarderFor: #MissingThing ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testSessionForwarderForUsesResolveSymbolAndAnswersProxy [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#UserGlobals')
			ifTrue: [ GbsProxy oop: 4242 session: mockSession ]
			ifFalse: [ nil ] ].

	result := mockSession sessionForwarderFor: #UserGlobals.

	self assert: (result isKindOf: GbsProxy).
	self assert: result oop equals: 4242.
	self assert: result session equals: mockSession
]

{ #category : 'tests' }
GbsSessionTest >> testForwardRemoteMessageMaterializesLocalDictionaryArguments [
	| mockSession proxy capturedScript result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		capturedScript := script.
		true ].
	proxy := GbsProxy oop: 4242 session: mockSession.

	result := proxy
		at: #MyTestDict
		put: (Dictionary new
			at: 'name' put: 'Tariq';
			at: 'amount' put: 100;
			yourself).

	self assert: result.
	self assert: (capturedScript includesSubstring: 'perform: #at:put:').
	self assert: (capturedScript includesSubstring: 'Dictionary new').
	self assert: (capturedScript includesSubstring: 'at: ''name'' put: ''Tariq''').
	self assert: (capturedScript includesSubstring: 'at: ''amount'' put: 100')
]

{ #category : 'running' }
GbsSessionTest >> testSignalTriggersNotification [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciPollForSignal put: 4.
	
	self should: [ mockSession checkSignals ] raise: TransactionBacklog
]

{ #category : 'tests' }
GbsSessionTest >> testUncachedForwarderAtIfAbsentReturnsFallbackWhenMissing [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObjectResult put: nil.

	result := mockSession
		uncachedForwarderAt: #MissingThing
		ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]
