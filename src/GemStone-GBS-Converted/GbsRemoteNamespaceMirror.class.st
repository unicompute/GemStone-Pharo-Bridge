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
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
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
		expression: (String streamContents: [ :stream |
			stream nextPutAll: '[:fullName | | parts current assoc value | '.
			stream nextPutAll: 'parts := fullName asString findTokens: ''::''. '.
			stream nextPutAll: 'current := Object nameSpace: 1. '.
			stream nextPutAll: 'parts do: [ :each | '.
			stream nextPutAll: 'current ifNotNil: [ '.
			stream nextPutAll: 'assoc := nil. value := nil. '.
			stream nextPutAll: '(current respondsTo: #rubyConstAssociationAt:) '.
			stream nextPutAll: 'ifTrue: [ assoc := [ current rubyConstAssociationAt: each asSymbol ] on: Error do: [ nil ]. '.
			stream nextPutAll: 'assoc ifNotNil: [ value := [ assoc value ] on: Error do: [ nil ] ] ]. '.
			stream nextPutAll: 'value ifNil: [ (current respondsTo: #at:) '.
			stream nextPutAll: 'ifTrue: [ value := [ current at: each asSymbol ] on: Error do: [ nil ] ] ]. '.
			stream nextPutAll: 'current := value ] ]. '.
			stream nextPutAll: 'current ] value: '.
			stream nextPutAll: (aSession marshalArgumentToScript: aString) ])
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
		expression: 'System myUserProfile symbolList at: ', anInteger printString
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
		expression: (String streamContents: [ :stream |
			stream nextPutAll: '[:cls | '.
			stream nextPutAll: 'cls ifNil: [ nil ] ifNotNil: [ cls nameSpace: 1 ]'.
			stream nextPutAll: '] value: '.
			stream nextPutAll: (aSession repository classExpressionFor: aClassOrName) ])
		symbolListIndex: nil
		metadata: nil
]

{ #category : 'instance creation' }
GbsRemoteNamespaceMirror class >> on: aSession object: anObjectOrProxy [
	^ self
		on: aSession
		expression: (String streamContents: [ :stream |
			stream nextPutAll: '[:value | value] value: '.
			stream nextPutAll: (aSession repository classExpressionFor: anObjectOrProxy) ])
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
GbsRemoteNamespaceMirror >> autoloadConstantMirrors [
	^ self constantMirrors select: [ :each | each isAutoload ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> autoloadEntries [
	^ autoloadEntries ifNil: [
		autoloadEntries := session executeScriptAndFetchObject: self autoloadEntriesScript ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> autoloadEntriesScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '| ns names entries assoc fileName loadState assocOop | '.
		stream nextPutAll: 'ns := '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: '. '.
		stream nextPutAll: 'ns ifNil: [ #() ] ifNotNil: [ '.
		stream nextPutAll: 'entries := OrderedCollection new. '.
		stream nextPutAll: 'names := ((ns respondsTo: #_rubyConstants) '.
		stream nextPutAll: 'ifTrue: [ ns _rubyConstants asArray ] '.
		stream nextPutAll: 'ifFalse: [ #() ]) asSortedCollection. '.
		stream nextPutAll: 'names do: [ :each | '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: each env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'assoc ifNotNil: [ '.
		stream nextPutAll: 'fileName := [ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'loadState := [ (assoc respondsTo: #isLoaded) ifTrue: [ assoc isLoaded ] ifFalse: [ false ] ] on: Error do: [ false ]. '.
		stream nextPutAll: 'assocOop := [ assoc asOop ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'entries add: (Array with: each asString with: fileName with: loadState with: assocOop) ] ]. '.
		stream nextPutAll: 'entries asArray ]' ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> autoloadMirrors [
	^ self autoloadEntries collect: [ :each |
		GbsRemoteAutoloadMirror on: self metadata: each ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> autoloadFileFor: aConstantName [
	^ session executeScriptAndFetchObject: (self autoloadFileScriptFor: aConstantName)
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> autoloadFileScriptFor: aConstantName [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name | '.
		stream nextPutAll: 'ns ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoloadFileFor:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadFileFor: name asSymbol ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString) ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> className [
	| metadata |
	metadata := self namespaceMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 4 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> constantEntries [
	^ constantEntries ifNil: [
		constantEntries := session executeScriptAndFetchObject: self constantEntriesScript ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> constantEntriesScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '| ns names entries assoc value autoloadFile valueClassName valueOop valueName valueFullName | '.
		stream nextPutAll: 'ns := '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: '. '.
		stream nextPutAll: 'ns ifNil: [ #() ] ifNotNil: [ '.
		stream nextPutAll: 'entries := OrderedCollection new. '.
		stream nextPutAll: 'names := ((ns respondsTo: #_rubyConstants) '.
		stream nextPutAll: 'ifTrue: [ ns _rubyConstants asArray ] '.
		stream nextPutAll: 'ifFalse: [ (ns respondsTo: #keys) ifTrue: [ ns keys asArray ] ifFalse: [ #() ] ]) asSortedCollection. '.
		stream nextPutAll: 'names do: [ :each | '.
		stream nextPutAll: 'assoc := nil. value := nil. autoloadFile := nil. valueName := nil. valueFullName := nil. '.
		stream nextPutAll: '(ns respondsTo: #rubyConstAssociationAt:) '.
		stream nextPutAll: 'ifTrue: [ '.
		stream nextPutAll: 'assoc := [ ns rubyConstAssociationAt: each ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'assoc ifNotNil: [ '.
		stream nextPutAll: 'autoloadFile := [ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'value := [ assoc value ] on: Error do: [ nil ] ] ] '.
		stream nextPutAll: 'ifFalse: [ (ns respondsTo: #at:) ifTrue: [ value := [ ns at: each ] on: Error do: [ nil ] ] ]. '.
		stream nextPutAll: 'valueClassName := value ifNil: [ nil ] ifNotNil: [ [ value class name asString ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'valueOop := value ifNil: [ nil ] ifNotNil: [ [ value asOop ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'valueName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #name) ifTrue: [ value name asString ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'valueFullName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #rubyFullName) ifTrue: [ value rubyFullName asString ] ifFalse: [ (value respondsTo: #fullName) ifTrue: [ value fullName asString ] ifFalse: [ nil ] ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'entries add: (Array with: each asString with: valueOop with: valueClassName with: autoloadFile with: valueName with: valueFullName) ]. '.
		stream nextPutAll: 'entries asArray ]' ]
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

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> loadFileNamed: aString [
	^ session rubyRuntime loadFileNamed: aString
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> loadedFeatures [
	^ session rubyRuntime loadedFeatures
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> loadPath [
	^ session rubyRuntime loadPath
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> persistentLoadedFeatures [
	^ session rubyRuntime persistentLoadedFeatures
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
		namespaceMetadata := session executeScriptAndFetchObject: self namespaceMetadataScript ]
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> namespaceMetadata: anArray [
	namespaceMetadata := anArray
		ifNil: [ nil ]
		ifNotNil: [ anArray asArray ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> namespaceMetadataScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '| ns name fullName myClassName | '.
		stream nextPutAll: 'ns := '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: '. '.
		stream nextPutAll: 'ns ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: 'name := [ (ns respondsTo: #name) ifTrue: [ ns name ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'fullName := [ (ns respondsTo: #fullName) ifTrue: [ ns fullName ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'myClassName := [ (ns respondsTo: #myClass) ifTrue: [ ns myClass ifNil: [ nil ] ifNotNil: [ ns myClass name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'Array with: ns asOop with: (name ifNil: [ nil ] ifNotNil: [ name asString ]) with: (fullName ifNil: [ nil ] ifNotNil: [ fullName asString ]) with: ns class name asString with: myClassName ]' ]
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

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> registerAutoload: aConstantName file: aFileName [
	| result |
	result := session executeScriptAndFetchObject: (self
		registerAutoloadScriptFor: aConstantName
		file: aFileName).
	self invalidate.
	^ result
]

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> removeAutoload: aConstantName [
	| result |
	result := session executeScriptAndFetchObject: (self removeAutoloadScriptFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> removeAutoloadScriptFor: aConstantName [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name | '.
		stream nextPutAll: '| assoc hasAutoload | '.
		stream nextPutAll: 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [ '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'hasAutoload := assoc notNil ifTrue: [ true ] ifFalse: [ '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoloadFileFor:) '.
		stream nextPutAll: 'ifTrue: [ [ (ns rubyAutoloadFileFor: name asSymbol) notNil ] on: Error do: [ false ] ] '.
		stream nextPutAll: 'ifFalse: [ false ] ]. '.
		stream nextPutAll: 'hasAutoload ifFalse: [ Error signal: ''Constant is not currently registered as an autoload.'' ]. '.
		stream nextPutAll: '(ns respondsTo: #removeConst:env:) '.
		stream nextPutAll: 'ifTrue: [ ns removeConst: name asSymbol env: 1. true ] '.
		stream nextPutAll: 'ifFalse: [ (ns respondsTo: #removeConst:) '.
		stream nextPutAll: 'ifTrue: [ ns removeConst: name asSymbol. true ] '.
		stream nextPutAll: 'ifFalse: [ Error signal: ''Namespace does not support autoload removal.'' ] ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString) ]
]

{ #category : 'private' }
GbsRemoteNamespaceMirror >> registerAutoloadScriptFor: aConstantName file: aFileName [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name :file | '.
		stream nextPutAll: 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [ '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoload:file:) '.
		stream nextPutAll: 'ifTrue: [ ns rubyAutoload: name asSymbol file: file. file ] '.
		stream nextPutAll: 'ifFalse: [ Error signal: ''Namespace does not support Ruby autoload.'' ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString).
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aFileName) ]
]

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> requireFileNamed: aString [
	^ session rubyRuntime requireFileNamed: aString
]

{ #category : 'actions' }
GbsRemoteNamespaceMirror >> clearPersistentLoadedFeatures [
	^ session rubyRuntime clearPersistentLoadedFeatures
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		scopeMethodReferenceStrings: (session implementorMethodReferenceStringsForSelector: aSelectorOrString)
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self
		scopeMethodReferenceStrings: (session methodReferenceStringsToSymbol: aSymbolOrString)
]

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		scopeMethodReferenceStrings: (session senderMethodReferenceStringsForSelector: aSelectorOrString)
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

{ #category : 'querying' }
GbsRemoteNamespaceMirror >> supportsAutoload [
	^ session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream nextPutAll: '[:ns | '.
		stream nextPutAll: 'ns notNil and: [ ns respondsTo: #rubyAutoload:file: ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression ])
]

{ #category : 'accessing' }
GbsRemoteNamespaceMirror >> symbolListIndex: anInteger [
	symbolListIndex := anInteger
]
