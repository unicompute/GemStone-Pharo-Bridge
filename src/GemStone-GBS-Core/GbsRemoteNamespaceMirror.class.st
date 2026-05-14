Class {
	#name : 'GbsRemoteNamespaceMirror',
	#superclass : 'Object',
	#instVars : [
		'session',
		'namespaceExpression',
		'symbolListIndex',
		'namespaceMetadata',
		'constantEntries',
		'autoloadEntries'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession expression: anExpressionString [
	^ self
		on: aSession
		expression: anExpressionString
		symbolListIndex: nil
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession fullName: aString [
	^ self
		on: aSession
		expression: ((GbsRemoteCommand
			blockBody: '| parts current value | parts := fullName asString findTokens: ''::''. current := Object nameSpace: 1. parts do: [ :each | current ifNotNil: [ value := nil. (current respondsTo: #at:) ifTrue: [ value := [ current at: each asSymbol ] on: Error do: [ nil ] ]. current := value ] ]. current'
			literalBindings: (Dictionary new
				at: 'fullName' put: aString;
				yourself)) script)
		symbolListIndex: nil
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession expression: anExpressionString symbolListIndex: anInteger metadata: aMetadataArray [
	^ self new
		session: aSession;
		namespaceExpression: anExpressionString;
		symbolListIndex: anInteger;
		namespaceMetadata: aMetadataArray;
		yourself
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession symbolListIndex: anInteger [
	^ self
		on: aSession
		expression: ((GbsRemoteCommand
			blockBody: 'System myUserProfile symbolList at: indexValue'
			literalBindings: (Dictionary new
				at: 'indexValue' put: anInteger;
				yourself)) script)
		symbolListIndex: anInteger
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession symbolListIndex: anInteger metadata: aMetadataArray [
	^ self
		on: aSession
		expression: 'System myUserProfile symbolList at: ', anInteger printString
		symbolListIndex: anInteger
		metadata: aMetadataArray
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession classOrModule: aClassOrName [
	^ self
		on: aSession
		expression: ((aSession repository
			remoteCommandForClassReferences: { 'cls' -> aClassOrName }
			body: 'cls ifNil: [ nil ] ifNotNil: [ cls nameSpace: 1 ]'
			literalAssignments: Dictionary new
			oopAssignments: Dictionary new) script)
		symbolListIndex: nil
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession object: anObjectOrProxy [
	^ self
		on: aSession
		expression: ((GbsRemoteCommand
			blockBody: 'value'
			argumentNames: #('value')
			argumentScripts: { aSession repository classExpressionFor: anObjectOrProxy }) script)
		symbolListIndex: nil
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> topLevelOn: aSession [
	^ self
		on: aSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: nil
]


{ #category : 'querying' }
GbsRemoteNamespaceMirror >> className [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 4 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedClassName [
	| metadata |
	metadata := namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 4 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedConstantMirrorAt: aConstantName ifAbsent: aBlock [
	| constantName |
	constantEntries ifNil: [ ^ aBlock value ].
	constantName := aConstantName asString.
	^ (constantEntries collect: [ :each |
		GbsRemoteConstantMirror on: self metadata: each ])
		detect: [ :each | each name = constantName ]
		ifNone: [ aBlock value ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedDisplayName [
	^ self cachedFullName
		ifNil: [ self cachedName
			ifNil: [ self cachedModuleName
				ifNil: [ self cachedClassName ] ] ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedFullName [
	| metadata |
	metadata := namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 3 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedModuleName [
	| metadata |
	metadata := namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 5 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> cachedName [
	| metadata |
	metadata := namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 2 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantEntries [
	^ constantEntries ifNil: [
		constantEntries := self fetchNamespaceBody: self constantEntriesCommandBody ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> constantEntriesCommandBody [
	^ '| names entries value valueClassName valueOop valueName valueFullName |
ns ifNil: [ #() ] ifNotNil: [
	entries := OrderedCollection new.
	names := ((ns respondsTo: #keys) ifTrue: [ ns keys asArray ] ifFalse: [ #() ]) asSortedCollection.
	names do: [ :each |
		value := nil. valueName := nil. valueFullName := nil.
		(ns respondsTo: #at:) ifTrue: [ value := [ ns at: each ] on: Error do: [ nil ] ].
		valueClassName := value ifNil: [ nil ] ifNotNil: [ [ value class name asString ] on: Error do: [ nil ] ].
		valueOop := value ifNil: [ nil ] ifNotNil: [ [ value asOop ] on: Error do: [ nil ] ].
		valueName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #name) ifTrue: [ value name asString ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
		valueFullName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #fullName) ifTrue: [ value fullName asString ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
		entries add: (Array with: each asString with: valueOop with: valueClassName with: nil with: valueName with: valueFullName) ].
	entries asArray ]'
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantMirrorAt: aConstantName [
	^ self
		constantMirrorAt: aConstantName
		ifAbsent: [ self error: aConstantName asString , ' not found in namespace' ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantMirrorAt: aConstantName ifAbsent: aBlock [
	| constantName |
	constantName := aConstantName asString.
	^ self constantMirrors
		detect: [ :each | each name = constantName ]
		ifNone: [ aBlock value ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantMirrors [
	^ self constantEntries collect: [ :each |
		GbsRemoteConstantMirror on: self metadata: each ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantNames [
	^ (self constantMirrors collect: [ :each | each name ]) asArray
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> displayName [
	| value |
	value := self fullName.
	value ifNotNil: [ ^ value ].
	value := self name.
	value ifNotNil: [ ^ value ].
	value := self moduleName.
	value ifNotNil: [ ^ value ].
	^ self className
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> exists [
	^ self namespaceMetadata notNil
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> fullName [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 3 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> index [
	^ symbolListIndex
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> isSymbolListNamespace [
	^ self index notNil
]

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> invalidate [
	namespaceMetadata := nil.
	constantEntries := nil.
	autoloadEntries := nil.
	^ self
]


{ #category : 'querying' }
GbsRemoteNamespaceMirror >> moduleName [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 5 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> name [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 2 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> namespaceExpression [
	^ namespaceExpression
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> namespaceExpression: aString [
	namespaceExpression := aString
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> namespaceMetadata [
	^ namespaceMetadata ifNil: [
		namespaceMetadata := self fetchNamespaceBody: self namespaceMetadataCommandBody ]
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> namespaceMetadata: anArray [
	namespaceMetadata := anArray
		ifNil: [ nil ]
		ifNotNil: [ anArray asArray ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> namespaceMetadataCommandBody [
	^ '| name fullName myClassName |
ns ifNil: [ nil ] ifNotNil: [
	name := [ (ns respondsTo: #name) ifTrue: [ ns name ] ifFalse: [ nil ] ] on: Error do: [ nil ].
	fullName := [ (ns respondsTo: #fullName) ifTrue: [ ns fullName ] ifFalse: [ nil ] ] on: Error do: [ nil ].
	myClassName := [ (ns respondsTo: #myClass) ifTrue: [ ns myClass ifNil: [ nil ] ifNotNil: [ ns myClass name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ].
	Array with: ns asOop with: (name ifNil: [ nil ] ifNotNil: [ name asString ]) with: (fullName ifNil: [ nil ] ifNotNil: [ fullName asString ]) with: ns class name asString with: myClassName ]'
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> fetchNamespaceBody: bodyString [
	^ session fetchRemoteCommand: (self namespaceCommandForBody: bodyString)
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> namespaceCommandForBody: bodyString [
	^ GbsRemoteCommand
		blockBody: bodyString
		argumentNames: #('ns')
		argumentScripts: { self namespaceExpression }
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> oop [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 1 ifAbsent: [ nil ]
]

{ #category : 'printing' }
GbsRemoteNamespaceMirror >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: (self displayName ifNil: [ self className ifNil: [ 'namespace' ] ]) asString.
	self index ifNotNil: [
		aStream
			nextPutAll: ' @';
			nextPutAll: self index printString ].
	aStream nextPut: $)
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ session objectForOop: oopValue
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> parentNamespaceMirror [
	| parent |
	self isSymbolListNamespace ifTrue: [ ^ nil ].
	self exists ifFalse: [ ^ nil ].
	parent := [ session namespaceMirrorForClass: self proxy ]
		on: Error
		do: [ :ex | nil ].
	parent ifNil: [ ^ nil ].
	((parent namespaceExpression = self namespaceExpression)
		or: [ parent oop notNil and: [ self oop notNil and: [ parent oop = self oop ] ] ])
		ifTrue: [ ^ nil ].
	^ parent
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> parentFullName [
	| segments |
	segments := self pathSegments.
	segments size <= 1 ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
		segments
			allButLast
			doWithIndex: [ :each :index |
				index > 1 ifTrue: [ stream nextPutAll: '::' ].
				stream nextPutAll: each asString ] ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> pathSegments [
	| pathString |
	pathString := self fullName
		ifNil: [ self displayName ].
	pathString ifNil: [ ^ #() ].
	^ pathString asString findTokens: '::'
]


{ #category : 'querying' }
GbsRemoteNamespaceMirror >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		scopeMethodReferenceStrings: (session implementorMethodReferenceStringsForSelector: aSelectorOrString)
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> implementorsQueryForSelector: aSelectorOrString [
	^ self
		methodQueryForMode: #implementors
		queryValue: aSelectorOrString asString
		references: (self implementorMethodReferenceStringsForSelector: aSelectorOrString)
		titlePrefix: 'Namespace Implementors of '
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self
		scopeMethodReferenceStrings: (session methodReferenceStringsToSymbol: aSymbolOrString)
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> methodQueryForMode: aSymbol queryValue: aValue references: aCollection titlePrefix: aString [
	^ GbsNamespaceScopedMethodQuery
		session: session
		namespace: self
		mode: aSymbol
		queryValue: aValue
		references: aCollection
		title: aString, aValue asString, ' (', (self displayName ifNil: [ 'namespace' ]), ')'
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> referencesQueryToSymbol: aSymbolOrString [
	^ self
		methodQueryForMode: #references
		queryValue: aSymbolOrString asString
		references: (self methodReferenceStringsToSymbol: aSymbolOrString)
		titlePrefix: 'Namespace References to '
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		scopeMethodReferenceStrings: (session senderMethodReferenceStringsForSelector: aSelectorOrString)
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> sendersQueryForSelector: aSelectorOrString [
	^ self
		methodQueryForMode: #senders
		queryValue: aSelectorOrString asString
		references: (self senderMethodReferenceStringsForSelector: aSelectorOrString)
		titlePrefix: 'Namespace Senders of '
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> scopeMethodReferenceStrings: aCollection [
	| scopeToken |
	aCollection ifNil: [ ^ #() ].
	scopeToken := self queryScopeToken.
	scopeToken ifNil: [ ^ aCollection asArray ].
	^ (aCollection select: [ :each |
		each asString includesSubstring: scopeToken ]) asArray
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> queryScopeToken [
	^ self fullName
		ifNil: [ self displayName ]
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> symbolListIndex: anInteger [
	symbolListIndex := anInteger
]
