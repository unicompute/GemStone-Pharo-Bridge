Extension { #name : 'GbsRemoteNamespaceMirror' }

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror class >> on: aSession fullName: aString [
	^ self
		on: aSession
		expression: ((GbsRemoteCommand
			blockBody: '| parts current assoc value |
parts := fullName asString findTokens: ''::''.
current := Object nameSpace: 1.
parts do: [ :each |
	current ifNotNil: [
		assoc := nil. value := nil.
		(current respondsTo: #rubyConstAssociationAt:)
			ifTrue: [
				assoc := [ current rubyConstAssociationAt: each asSymbol ] on: Error do: [ nil ].
				assoc ifNotNil: [ value := [ assoc value ] on: Error do: [ nil ] ] ].
		value ifNil: [
			(current respondsTo: #at:)
				ifTrue: [ value := [ current at: each asSymbol ] on: Error do: [ nil ] ] ].
		current := value ] ].
current'
			literalBindings: (Dictionary new
				at: 'fullName' put: aString;
				yourself)) script)
		symbolListIndex: nil
		metadata: nil
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadConstantMirrors [
	^ self constantMirrors select: [ :each | each isAutoload ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> constantEntriesScript [
	^ (self namespaceCommandForBody: self constantEntriesCommandBody) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> constantEntriesCommandBody [
	^ '| names entries assoc value autoloadFile valueClassName valueOop valueName valueFullName |
ns ifNil: [ #() ] ifNotNil: [
	entries := OrderedCollection new.
	names := ((ns respondsTo: #_rubyConstants)
		ifTrue: [ ns _rubyConstants asArray ]
		ifFalse: [ (ns respondsTo: #keys) ifTrue: [ ns keys asArray ] ifFalse: [ #() ] ]) asSortedCollection.
	names do: [ :each |
		assoc := nil. value := nil. autoloadFile := nil. valueName := nil. valueFullName := nil.
		(ns respondsTo: #rubyConstAssociationAt:)
			ifTrue: [
				assoc := [ ns rubyConstAssociationAt: each ] on: Error do: [ nil ].
				assoc ifNotNil: [
					autoloadFile := [ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ].
					value := [ assoc value ] on: Error do: [ nil ] ] ]
			ifFalse: [
				(ns respondsTo: #at:)
					ifTrue: [ value := [ ns at: each ] on: Error do: [ nil ] ] ].
		valueClassName := value ifNil: [ nil ] ifNotNil: [ [ value class name asString ] on: Error do: [ nil ] ].
		valueOop := value ifNil: [ nil ] ifNotNil: [ [ value asOop ] on: Error do: [ nil ] ].
		valueName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #name) ifTrue: [ value name asString ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
		valueFullName := value ifNil: [ nil ] ifNotNil: [ [ (value respondsTo: #rubyFullName) ifTrue: [ value rubyFullName asString ] ifFalse: [ (value respondsTo: #fullName) ifTrue: [ value fullName asString ] ifFalse: [ nil ] ] ] on: Error do: [ nil ] ].
		entries add: (Array with: each asString with: valueOop with: valueClassName with: autoloadFile with: valueName with: valueFullName) ].
	entries asArray ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> namespaceCommandForBody: bodyString literalBindings: literalDictionary [
	| builder names scripts |
	builder := GbsRemoteScriptBuilder new.
	names := OrderedCollection with: 'ns'.
	scripts := OrderedCollection with: self namespaceExpression.
	literalDictionary keys asArray sorted do: [ :key |
		names add: key.
		scripts add: (builder literalFor: (literalDictionary at: key)) ].
	^ GbsRemoteCommand
		blockBody: bodyString
		argumentNames: names asArray
		argumentScripts: scripts asArray
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadEntries [
	^ autoloadEntries ifNil: [
		autoloadEntries := session fetchRemoteCommand: (self namespaceCommandForBody: self autoloadEntriesCommandBody) ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadEntriesScript [
	^ (self namespaceCommandForBody: self autoloadEntriesCommandBody) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadEntriesCommandBody [
	^ '| tns cache pns names entries assoc fileName loadState assocOop persistentFile transientCached failureDetail retryDetail failureSource failureMessage lastAttemptedFile retrySource exceptionObj exceptionOop backtraceText |
ns ifNil: [ #() ] ifNotNil: [
	tns := ((ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ]).
	cache := (tns notNil and: [ tns respondsTo: #autoloadCache ])
		ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	pns := tns ifNil: [ nil ] ifNotNil: [
		[ (tns respondsTo: #persistCopy) ifTrue: [ tns persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
	entries := OrderedCollection new.
	names := ((ns respondsTo: #_rubyConstants)
		ifTrue: [ ns _rubyConstants asArray ]
		ifFalse: [ #() ]) asSortedCollection.
	names do: [ :each |
		assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
			ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: each env: 1 ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		assoc ifNotNil: [
			fileName := [ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ].
			loadState := [ (assoc respondsTo: #isLoaded) ifTrue: [ assoc isLoaded ] ifFalse: [ false ] ] on: Error do: [ false ].
			assocOop := [ assoc asOop ] on: Error do: [ nil ].
			persistentFile := pns ifNil: [ nil ] ifNotNil: [
				[ (pns respondsTo: #rubyAutoloadFileFor:) ifTrue: [ pns rubyAutoloadFileFor: each ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
			transientCached := [ cache notNil and: [ cache anySatisfy: [ :cached | | cachedKey |
				cachedKey := [ cached key ] on: Error do: [ nil ].
				cached == assoc or: [ cachedKey = each ] ] ] ] on: Error do: [ false ].
			failureSource := fileName notNil ifTrue: [ ''Current Registration'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Transient Cache + Persistent Registration'' ] ifFalse: [ ''Transient Cache'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Persistent Registration'' ] ifFalse: [ ''Missing'' ] ] ].
			failureDetail := loadState == true ifTrue: [ ''Loaded successfully.'' ] ifFalse: [ loadState isNil ifTrue: [ ''Autoload is currently loading.'' ] ifFalse: [ fileName notNil ifTrue: [ ''Current registration is ready to load '', fileName asString ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Transient cache is shadowing persistent registration '', persistentFile asString ] ifFalse: [ ''Transient cache must be reset before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Persistent registration can recover '', persistentFile asString ] ifFalse: [ ''No recoverable autoload registration was found.'' ] ] ] ] ].
			retryDetail := fileName notNil ifTrue: [ ''Retry current registration.'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Reset transient cache, then recover persistent registration.'' ] ifFalse: [ ''Reset transient cache before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Recover persistent registration before retry.'' ] ifFalse: [ ''Retry unavailable.'' ] ] ].
			lastAttemptedFile := fileName ifNil: [ persistentFile ].
			retrySource := fileName notNil ifTrue: [ ''current'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''persistent-after-reset'' ] ifFalse: [ ''transient-reset'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''persistent'' ] ifFalse: [ ''missing'' ] ] ].
			failureMessage := loadState isNil ifTrue: [ ''Autoload is currently loading.'' ] ifFalse: [ loadState == true ifTrue: [ ''Autoload load completed successfully.'' ] ifFalse: [ fileName notNil ifTrue: [ ''No previous autoload failure is recorded for the current registration.'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''A transient cache entry remains from a failed or interrupted autoload attempt.'' ] ifFalse: [ ''A transient cache entry remains and must be reset before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Retry will rebuild the transient autoload state from the persistent registration.'' ] ifFalse: [ ''No autoload failure metadata is available.'' ] ] ] ] ].
			exceptionObj := [ (assoc respondsTo: #lastException) ifTrue: [ assoc lastException ] ifFalse: [ nil ] ] on: Error do: [ nil ].
			exceptionObj ifNil: [ exceptionObj := [ (assoc respondsTo: #exception) ifTrue: [ assoc exception ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
			exceptionObj ifNil: [ exceptionObj := [ (assoc respondsTo: #error) ifTrue: [ assoc error ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
			exceptionOop := exceptionObj ifNil: [ nil ] ifNotNil: [ [ exceptionObj asOop ] on: Error do: [ nil ] ].
			backtraceText := exceptionObj ifNil: [ nil ] ifNotNil: [ [ (exceptionObj respondsTo: #backtrace) ifTrue: [ | bt | bt := exceptionObj backtrace. bt ifNil: [ nil ] ifNotNil: [ bt printString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
			backtraceText ifNil: [ backtraceText := [ (assoc respondsTo: #lastExceptionBacktrace) ifTrue: [ | bt | bt := assoc lastExceptionBacktrace. bt ifNil: [ nil ] ifNotNil: [ bt printString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
			entries add: (Array with: each asString with: fileName with: loadState with: assocOop with: persistentFile with: transientCached with: (persistentFile notNil) with: failureDetail with: retryDetail with: failureSource with: failureMessage with: lastAttemptedFile with: retrySource with: exceptionOop with: backtraceText) ] ].
	entries asArray ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadFileFor: aConstantName [
	^ session fetchRemoteCommand: (self autoloadFileCommandFor: aConstantName)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadFileScriptFor: aConstantName [
	^ (self autoloadFileCommandFor: aConstantName) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadFileCommandFor: aConstantName [
	^ self
		namespaceCommandForBody: self autoloadFileCommandBody
		literalBindings: (Dictionary new
			at: 'name' put: aConstantName asString;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadFileCommandBody [
	^ 'ns ifNil: [ nil ] ifNotNil: [
	(ns respondsTo: #rubyAutoloadFileFor:)
		ifTrue: [ [ ns rubyAutoloadFileFor: name asSymbol ] on: Error do: [ nil ] ]
		ifFalse: [ nil ] ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadMirrors [
	^ self autoloadEntries collect: [ :each |
		GbsRemoteAutoloadMirror on: self metadata: each ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearPersistentLoadedFeatures [
	^ session rubyRuntime clearPersistentLoadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearTransientAutoloadCache [
	| result |
	result := session fetchRemoteCommand: self clearTransientAutoloadCacheCommand.
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearTransientAutoloadCacheScript [
	^ self clearTransientAutoloadCacheCommand script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearTransientAutoloadCacheCommand [
	^ self namespaceCommandForBody: self clearTransientAutoloadCacheCommandBody
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearTransientAutoloadCacheCommandBody [
	^ '| tns cache |
ns ifNil: [ false ] ifNotNil: [
	tns := ((ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ]).
	cache := (tns notNil and: [ tns respondsTo: #autoloadCache ])
		ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	cache ifNil: [ false ] ifNotNil: [
		[ (cache respondsTo: #removeAll) ifTrue: [ cache removeAll ] ] on: Error do: [ ].
		true ] ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> loadFileNamed: aString [
	^ session rubyRuntime loadFileNamed: aString
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> loadedFeatures [
	^ session rubyRuntime loadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> loadPath [
	^ session rubyRuntime loadPath
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> persistentLoadedFeatures [
	^ session rubyRuntime persistentLoadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> recoverAutoload: aConstantName [
	| result |
	result := session fetchRemoteCommand: (self recoverAutoloadCommandFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> recoverAutoloadScriptFor: aConstantName [
	^ (self recoverAutoloadCommandFor: aConstantName) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> recoverAutoloadCommandFor: aConstantName [
	^ self
		namespaceCommandForBody: self recoverAutoloadCommandBody
		literalBindings: (Dictionary new
			at: 'name' put: aConstantName asString;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> recoverAutoloadCommandBody [
	^ '| assoc fileName tns cache pns |
ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [
	assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
		ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	fileName := assoc ifNil: [ nil ] ifNotNil: [
		[ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
	tns := ((ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ]).
	cache := (tns notNil and: [ tns respondsTo: #autoloadCache ])
		ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(fileName isNil and: [ cache notNil ]) ifTrue: [
		[ cache do: [ :cached | | cachedKey cachedValue |
			cachedKey := [ cached key ] on: Error do: [ nil ].
			cachedValue := [ cached value ] on: Error do: [ nil ].
			((cachedKey = name asSymbol) or: [ cachedKey = name ]) ifTrue: [
				fileName ifNil: [ fileName := [ cachedValue fileName ] on: Error do: [ nil ] ] ] ] ] on: Error do: [ ] ].
	pns := tns ifNil: [ nil ] ifNotNil: [
		[ (tns respondsTo: #persistCopy) ifTrue: [ tns persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
	(fileName isNil and: [ pns notNil ]) ifTrue: [
		fileName := [ (pns respondsTo: #rubyAutoloadFileFor:) ifTrue: [ pns rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
	fileName ifNil: [ Error signal: ''Autoload file could not be recovered.'' ].
	(ns respondsTo: #rubyAutoload:file:)
		ifTrue: [ ns rubyAutoload: name asSymbol file: fileName. fileName ]
		ifFalse: [ Error signal: ''Namespace does not support Ruby autoload.'' ] ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> registerAutoload: aConstantName file: aFileName [
	| result |
	result := session fetchRemoteCommand: (self
		registerAutoloadCommandFor: aConstantName
		file: aFileName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> registerAutoloadScriptFor: aConstantName file: aFileName [
	^ (self
		registerAutoloadCommandFor: aConstantName
		file: aFileName) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> registerAutoloadCommandFor: aConstantName file: aFileName [
	^ self
		namespaceCommandForBody: self registerAutoloadCommandBody
		literalBindings: (Dictionary new
			at: 'file' put: aFileName;
			at: 'name' put: aConstantName asString;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> registerAutoloadCommandBody [
	^ 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [
	(ns respondsTo: #rubyAutoload:file:)
		ifTrue: [ ns rubyAutoload: name asSymbol file: file. file ]
		ifFalse: [ Error signal: ''Namespace does not support Ruby autoload.'' ] ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> removeAutoload: aConstantName [
	| result |
	result := session fetchRemoteCommand: (self removeAutoloadCommandFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> removeAutoloadScriptFor: aConstantName [
	^ (self removeAutoloadCommandFor: aConstantName) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> removeAutoloadCommandFor: aConstantName [
	^ self
		namespaceCommandForBody: self removeAutoloadCommandBody
		literalBindings: (Dictionary new
			at: 'name' put: aConstantName asString;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> removeAutoloadCommandBody [
	^ '| assoc hasAutoload |
ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [
	assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
		ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	hasAutoload := assoc notNil ifTrue: [ true ] ifFalse: [
		(ns respondsTo: #rubyAutoloadFileFor:)
			ifTrue: [ [ (ns rubyAutoloadFileFor: name asSymbol) notNil ] on: Error do: [ false ] ]
			ifFalse: [ false ] ].
	hasAutoload ifFalse: [ Error signal: ''Constant is not currently registered as an autoload.'' ].
	(ns respondsTo: #removeConst:env:)
		ifTrue: [ ns removeConst: name asSymbol env: 1. true ]
		ifFalse: [ (ns respondsTo: #removeConst:)
			ifTrue: [ ns removeConst: name asSymbol. true ]
			ifFalse: [ Error signal: ''Namespace does not support autoload removal.'' ] ] ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> requireFileNamed: aString [
	^ session rubyRuntime requireFileNamed: aString
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoload: aConstantName [
	| result |
	result := session fetchRemoteCommand: (self resetAutoloadCommandFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoloadScriptFor: aConstantName [
	^ (self resetAutoloadCommandFor: aConstantName) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoloadCommandFor: aConstantName [
	^ self
		namespaceCommandForBody: self resetAutoloadCommandBody
		literalBindings: (Dictionary new
			at: 'name' put: aConstantName asString;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoloadCommandBody [
	^ '| assoc fileName transient |
ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [
	assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
		ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	fileName := assoc ifNil: [ nil ] ifNotNil: [ [ assoc fileName ] on: Error do: [ nil ] ].
	fileName ifNil: [
		(ns respondsTo: #rubyAutoloadFileFor:)
			ifTrue: [ fileName := [ ns rubyAutoloadFileFor: name asSymbol ] on: Error do: [ nil ] ] ].
	assoc ifNotNil: [
		(ns respondsTo: #removeConst:env:)
			ifTrue: [ [ ns removeConst: name asSymbol env: 1 ] on: Error do: [ ] ]
			ifFalse: [ (ns respondsTo: #removeConst:) ifTrue: [ [ ns removeConst: name asSymbol ] on: Error do: [ ] ] ] ].
	transient := (ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: false ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	transient ifNotNil: [
		(transient respondsTo: #removeKey:ifAbsent:)
			ifTrue: [ [ transient removeKey: name asSymbol ifAbsent: [ ] ] on: Error do: [ ] ] ].
	fileName ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoload: aConstantName [
	| result |
	result := session fetchRemoteCommand: (self retryAutoloadCommandFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoload: aConstantName usingSourceKind: aSourceKind [
	| result |
	result := session fetchRemoteCommand: (self
		retryAutoloadCommandFor: aConstantName
		usingSourceKind: aSourceKind).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoloadScriptFor: aConstantName [
	^ self
		retryAutoloadScriptFor: aConstantName
		usingSourceKind: nil
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoloadScriptFor: aConstantName usingSourceKind: aSourceKind [
	^ (self
		retryAutoloadCommandFor: aConstantName
		usingSourceKind: aSourceKind) script
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoloadCommandFor: aConstantName [
	^ self
		retryAutoloadCommandFor: aConstantName
		usingSourceKind: nil
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoloadCommandFor: aConstantName usingSourceKind: aSourceKind [
	^ self
		namespaceCommandForBody: self retryAutoloadCommandBody
		literalBindings: (Dictionary new
			at: 'name' put: aConstantName asString;
			at: 'sourceKind' put: aSourceKind;
			yourself)
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoloadCommandBody [
	^ '| assoc fileName currentFile transient transientStore cache transientFile persist fileWasReset selectedSource resetTransient |
ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [
	selectedSource := sourceKind ifNil: [ nil ] ifNotNil: [ sourceKind asString ].
	assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
		ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	currentFile := assoc ifNil: [ nil ] ifNotNil: [ [ assoc fileName ] on: Error do: [ nil ] ].
	transientStore := (ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	cache := (transientStore notNil and: [ transientStore respondsTo: #autoloadCache ])
		ifTrue: [ [ transientStore autoloadCache ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	transientFile := nil.
	cache ifNotNil: [ [ cache do: [ :cached | | cachedKey cachedValue |
		cachedKey := [ cached key ] on: Error do: [ nil ].
		cachedValue := [ cached value ] on: Error do: [ nil ].
		((cachedKey = name asSymbol) or: [ cachedKey = name ]) ifTrue: [
			transientFile ifNil: [ transientFile := [ (cachedValue respondsTo: #fileName) ifTrue: [ cachedValue fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ] ] ] on: Error do: [ ] ].
	persist := transientStore ifNil: [ nil ] ifNotNil: [ [ (transientStore respondsTo: #persistCopy) ifTrue: [ transientStore persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ].
	persist ifNil: [ persist := (ns respondsTo: #persistCopy) ifTrue: [ [ ns persistCopy ] on: Error do: [ nil ] ] ifFalse: [ nil ] ].
	fileName := nil.
	selectedSource = ''current'' ifTrue: [ fileName := currentFile ].
	selectedSource = ''transient-reset'' ifTrue: [ fileName := transientFile ].
	selectedSource = ''persistent'' ifTrue: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ].
	selectedSource = ''persistent-after-reset'' ifTrue: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ].
	fileName ifNil: [ fileName := currentFile ].
	fileName ifNil: [ fileName := transientFile ].
	fileName ifNil: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ].
	fileName ifNil: [ Error signal: ''Autoload registration is not recoverable.'' ].
	fileWasReset := false.
	resetTransient := selectedSource = ''transient-reset'' or: [ selectedSource = ''persistent-after-reset'' ].
	assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:)
		ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	assoc ifNotNil: [
		(ns respondsTo: #removeConst:env:)
			ifTrue: [ [ ns removeConst: name asSymbol env: 1 ] on: Error do: [ ] ]
			ifFalse: [ (ns respondsTo: #removeConst:) ifTrue: [ [ ns removeConst: name asSymbol ] on: Error do: [ ] ] ].
		fileWasReset := true ].
	transient := (ns respondsTo: #transientNameSpaceForStore:)
		ifTrue: [ [ ns transientNameSpaceForStore: false ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	resetTransient ifTrue: [ transient ifNotNil: [
		(transient respondsTo: #removeKey:ifAbsent:)
			ifTrue: [ [ transient removeKey: name asSymbol ifAbsent: [ ] ] on: Error do: [ ] ] ].
		fileWasReset := true ].
	(ns respondsTo: #rubyAutoload:file:)
		ifTrue: [ ns rubyAutoload: name asSymbol file: fileName ]
		ifFalse: [ Error signal: ''Namespace does not support rubyAutoload:file:.'' ].
	Array with: fileName with: fileWasReset with: (selectedSource ifNil: [ ''auto'' ]) ]'
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> supportsAutoload [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		blockBody: 'ns notNil and: [ ns respondsTo: #rubyAutoload:file: ]'
		argumentNames: #('ns')
		argumentScripts: { self namespaceExpression })
]
