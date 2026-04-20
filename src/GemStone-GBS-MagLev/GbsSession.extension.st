Extension { #name : 'GbsSession' }

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> procObjectFor: anObject [
	^ GbsRemoteProcObject
		on: self
		object: anObject
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> procObjectForOop: anOop [
	^ GbsRemoteProcObject
		on: self
		oop: anOop
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> bindingObjectForProc: anObject [
	| procObject |
	procObject := self procObjectFor: anObject.
	^ procObject
		ifNil: [ nil ]
		ifNotNil: [ procObject bindingObject ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> bindingObjectForProcOop: anOop [
	| procObject |
	procObject := self procObjectForOop: anOop.
	^ procObject
		ifNil: [ nil ]
		ifNotNil: [ procObject bindingObject ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> execBlockObjectFor: anObject [
	| procObject |
	procObject := self procObjectFor: anObject.
	^ (procObject isKindOf: GbsRemoteExecBlockObject)
		ifTrue: [ procObject ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> execBlockObjectForOop: anOop [
	| procObject |
	procObject := self procObjectForOop: anOop.
	^ (procObject isKindOf: GbsRemoteExecBlockObject)
		ifTrue: [ procObject ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyLoadPath [
	^ self executeScriptAndFetchObject: 'RubyFile loadPath: 1'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyLoadedFeatures [
	^ self executeScriptAndFetchObject: 'RubyContext default transientLoadedFeatures: 1'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyPersistentLoadedFeatures [
	^ self executeScriptAndFetchObject: 'RubyContext default persistentLoadedFeatures: 1'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyRequireFileNamed: aString [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'RubyContext default requireFileNamed: ';
			nextPutAll: (self marshalArgumentToScript: aString);
			nextPutAll: ' env: 1' ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyLoadFileNamed: aString [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'RubyContext default loadFileNamed: ';
			nextPutAll: (self marshalArgumentToScript: aString);
			nextPutAll: ' env: 1' ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyRequireRelativeFileNamed: aString relativeTo: aBasePath [
	| resolvedPath |
	resolvedPath := self
		rubyResolvedRelativePath: aString
		relativeTo: aBasePath.
	resolvedPath ifNil: [ ^ nil ].
	^ self rubyRequireFileNamed: resolvedPath
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyLoadRelativeFileNamed: aString relativeTo: aBasePath [
	| resolvedPath |
	resolvedPath := self
		rubyResolvedRelativePath: aString
		relativeTo: aBasePath.
	resolvedPath ifNil: [ ^ nil ].
	^ self rubyLoadFileNamed: resolvedPath
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyResolvedRelativePath: aString relativeTo: aBasePath [
	| relativePath basePath baseDirectory absolutePath segments |
	relativePath := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth ].
	basePath := aBasePath ifNil: [ '' ] ifNotNil: [ aBasePath asString trimBoth ].
	relativePath isEmpty ifTrue: [ ^ nil ].
	(relativePath beginsWith: '/') ifTrue: [ ^ relativePath ].
	basePath isEmpty ifTrue: [ ^ relativePath ].
	baseDirectory := ((basePath endsWith: '/')
		or: [ basePath endsWith: '\' ])
		ifTrue: [ basePath copyFrom: 1 to: basePath size - 1 ]
		ifFalse: [
			(basePath includes: $/)
				ifTrue: [ basePath copyUpToLast: $/ ]
				ifFalse: [ '' ] ].
	absolutePath := baseDirectory beginsWith: '/'.
	segments := OrderedCollection new.
	(baseDirectory findTokens: '/') do: [ :each |
		each isEmpty ifFalse: [ segments add: each ] ].
	(relativePath findTokens: '/') do: [ :each |
		each = '.' ifFalse: [
			each = '..'
				ifTrue: [ segments ifNotEmpty: [ segments removeLast ] ]
				ifFalse: [ segments add: each ] ] ].
	^ String streamContents: [ :stream |
		absolutePath ifTrue: [ stream nextPut: $/ ].
		segments doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPut: $/ ].
			stream nextPutAll: each asString ] ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> clearPersistentRubyLoadedFeatures [
	^ self executeScriptAndFetchObject: 'RubyContext clear_persistent_LOADED_FEATURES'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyRuntime [
	^ GbsRubyRuntimeFacade on: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> sessionMethods [
	^ self symbolDictionaryNamed: #SessionMethods
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> maglev [
	^ GbsMaglevFacade on: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rubyRuntimeReport [
	^ self rubyRuntime report
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> maglevPersistentRoot [
	^ self bridgeRoot
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> maglevSymbolDictionaryNamed: aName [
	^ self symbolDictionaryNamed: aName
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> beginNestedTransaction [
	^ self executeScriptAndFetchObject: 'System begin_nested_transaction'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> transactionLevel [
	^ self executeScriptAndFetchObject: 'System transactionLevel'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> commitAndReleaseLocks [
	^ self executeScriptAndFetchObject: 'System commitAndReleaseLocks'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> commitAndReleaseLocksOrSignalConflict [
	(self commitAndReleaseLocks == true)
		ifTrue: [ ^ true ].
	GbsCommitConflictError signal: 'GemStone commit and release locks conflict.'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> withCommitAndReleaseLocksRetryCount: aRetryCount do: aBlock [
	| retries attempts result |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		result := aBlock value.
		(self commitAndReleaseLocks == true) ifTrue: [ ^ result ].
		attempt < attempts ifTrue: [ self abortTransaction ] ].
	GbsCommitConflictError signal: 'GemStone commit and release locks conflict after ', attempts printString, ' attempts.'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> sharedCounterAt: anIndex [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'System sharedCounter: ';
			nextPutAll: anIndex asInteger printString ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> sessionCount [
	^ self executeScriptAndFetchObject: 'System sessionCount'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> sharedCounterAt: anIndex put: anInteger [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'System sharedCounter: ';
			nextPutAll: anIndex asInteger printString;
			nextPutAll: ' setValue: ';
			nextPutAll: anInteger asInteger printString ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> incrementSharedCounterAt: anIndex by: anInteger [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'System sharedCounter: ';
			nextPutAll: anIndex asInteger printString;
			nextPutAll: ' incrementBy: ';
			nextPutAll: anInteger asInteger printString ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> decrementSharedCounterAt: anIndex by: anInteger [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: 'System sharedCounter: ';
			nextPutAll: anIndex asInteger printString;
			nextPutAll: ' decrementBy: ';
			nextPutAll: anInteger asInteger printString ])
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> newRcCounter [
	| oop |
	oop := self executeScriptAndReturnOop: 'RcCounter new'.
	^ self rcCounterForOop: oop
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> newRcHash [
	| oop |
	oop := self executeScriptAndReturnOop: 'RcKeyValueDictionary new'.
	^ self rcHashForOop: oop
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> newRcQueue [
	| oop |
	oop := self executeScriptAndReturnOop: 'RcQueue new'.
	^ self rcQueueForOop: oop
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> maglevFinalizerRegistry [
	^ self objectSpace maglevFinalizerRegistry
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> objectLog [
	^ GbsObjectLogFacade on: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> materializeMaglevRuntimeValue: anObject [
	^ self materializeRuntimeValue: anObject
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> materializeRuntimeValue: anObject [
	| oopValue className |
	anObject ifNil: [ ^ nil ].
	(anObject isKindOf: GbsProxy) ifFalse: [ ^ anObject ].
	anObject class ~~ GbsProxy ifTrue: [ ^ anObject ].
	(anObject respondsTo: #oop) ifFalse: [ ^ anObject ].
	oopValue := anObject oop.
	oopValue ifNil: [ ^ anObject ].
	className := [ self remoteClassNameForOop: oopValue ] on: Error do: [ nil ].
	className ifNil: [ ^ anObject ].
	className = 'RcCounter' ifTrue: [ ^ self rcCounterForOop: oopValue ].
	className = 'RcKeyValueDictionary' ifTrue: [ ^ self rcHashForOop: oopValue ].
	className = 'RcQueue' ifTrue: [ ^ self rcQueueForOop: oopValue ].
	className = 'StringKeyValueDictionary' ifTrue: [ ^ self gsDictionaryForOop: oopValue ].
	className = 'SymbolDictionary' ifTrue: [ ^ self gsDictionaryForOop: oopValue ].
	((className = 'Proc' or: [ className beginsWith: 'ExecBlock' ])
		and: [ self respondsTo: #procObjectForOop: ]) ifTrue: [
		^ self perform: #procObjectForOop: with: oopValue ].
	^ self gsObjectForOop: oopValue
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> gsDictionaryForOop: anOop [
	^ GbsGsDictionary oop: anOop session: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> gsObjectForOop: anOop [
	^ GbsGsObject oop: anOop session: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rcCounterForOop: anOop [
	^ GbsRcCounter oop: anOop session: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rcHashForOop: anOop [
	^ GbsRcHash oop: anOop session: self
]

{ #category : '*GemStone-GBS-MagLev' }
GbsSession >> rcQueueForOop: anOop [
	^ GbsRcQueue oop: anOop session: self
]
