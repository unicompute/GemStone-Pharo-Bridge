Extension { #name : 'GbsRemoteNamespaceMirror' }

{ #category : '*GemStone-GBS-MagLev' }
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

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadConstantMirrors [
	^ self constantMirrors select: [ :each | each isAutoload ]
]

{ #category : '*GemStone-GBS-MagLev' }
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

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadEntries [
	^ autoloadEntries ifNil: [
		autoloadEntries := session executeScriptAndFetchObject: self autoloadEntriesScript ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadEntriesScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '| ns tns cache pns names entries assoc fileName loadState assocOop persistentFile transientCached failureDetail retryDetail failureSource failureMessage lastAttemptedFile retrySource exceptionObj exceptionOop backtraceText | '.
		stream nextPutAll: 'ns := '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: '. '.
		stream nextPutAll: 'ns ifNil: [ #() ] ifNotNil: [ '.
		stream nextPutAll: 'tns := ((ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]). '.
		stream nextPutAll: 'cache := (tns notNil and: [ tns respondsTo: #autoloadCache ]) '.
		stream nextPutAll: 'ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'pns := tns ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: '[ (tns respondsTo: #persistCopy) ifTrue: [ tns persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
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
		stream nextPutAll: 'persistentFile := pns ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: '[ (pns respondsTo: #rubyAutoloadFileFor:) ifTrue: [ pns rubyAutoloadFileFor: each ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'transientCached := [ cache notNil and: [ cache anySatisfy: [ :cached | | cachedKey | '.
		stream nextPutAll: 'cachedKey := [ cached key ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'cached == assoc or: [ cachedKey = each ] ] ] ] on: Error do: [ false ]. '.
		stream nextPutAll: 'failureSource := fileName notNil ifTrue: [ ''Current Registration'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Transient Cache + Persistent Registration'' ] ifFalse: [ ''Transient Cache'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Persistent Registration'' ] ifFalse: [ ''Missing'' ] ] ]. '.
		stream nextPutAll: 'failureDetail := loadState == true ifTrue: [ ''Loaded successfully.'' ] ifFalse: [ loadState isNil ifTrue: [ ''Autoload is currently loading.'' ] ifFalse: [ fileName notNil ifTrue: [ ''Current registration is ready to load '', fileName asString ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Transient cache is shadowing persistent registration '', persistentFile asString ] ifFalse: [ ''Transient cache must be reset before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Persistent registration can recover '', persistentFile asString ] ifFalse: [ ''No recoverable autoload registration was found.'' ] ] ] ] ]. '.
		stream nextPutAll: 'retryDetail := fileName notNil ifTrue: [ ''Retry current registration.'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''Reset transient cache, then recover persistent registration.'' ] ifFalse: [ ''Reset transient cache before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Recover persistent registration before retry.'' ] ifFalse: [ ''Retry unavailable.'' ] ] ]. '.
		stream nextPutAll: 'lastAttemptedFile := fileName ifNil: [ persistentFile ]. '.
		stream nextPutAll: 'retrySource := fileName notNil ifTrue: [ ''current'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''persistent-after-reset'' ] ifFalse: [ ''transient-reset'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''persistent'' ] ifFalse: [ ''missing'' ] ] ]. '.
		stream nextPutAll: 'failureMessage := loadState isNil ifTrue: [ ''Autoload is currently loading.'' ] ifFalse: [ loadState == true ifTrue: [ ''Autoload load completed successfully.'' ] ifFalse: [ fileName notNil ifTrue: [ ''No previous autoload failure is recorded for the current registration.'' ] ifFalse: [ transientCached ifTrue: [ persistentFile notNil ifTrue: [ ''A transient cache entry remains from a failed or interrupted autoload attempt.'' ] ifFalse: [ ''A transient cache entry remains and must be reset before retry.'' ] ] ifFalse: [ persistentFile notNil ifTrue: [ ''Retry will rebuild the transient autoload state from the persistent registration.'' ] ifFalse: [ ''No autoload failure metadata is available.'' ] ] ] ] ]. '.
		stream nextPutAll: 'exceptionObj := [ (assoc respondsTo: #lastException) ifTrue: [ assoc lastException ] ifFalse: [ nil ] ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'exceptionObj ifNil: [ exceptionObj := [ (assoc respondsTo: #exception) ifTrue: [ assoc exception ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'exceptionObj ifNil: [ exceptionObj := [ (assoc respondsTo: #error) ifTrue: [ assoc error ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'exceptionOop := exceptionObj ifNil: [ nil ] ifNotNil: [ [ exceptionObj asOop ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'backtraceText := exceptionObj ifNil: [ nil ] ifNotNil: [ [ (exceptionObj respondsTo: #backtrace) ifTrue: [ | bt | bt := exceptionObj backtrace. bt ifNil: [ nil ] ifNotNil: [ bt printString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'backtraceText ifNil: [ backtraceText := [ (assoc respondsTo: #lastExceptionBacktrace) ifTrue: [ | bt | bt := assoc lastExceptionBacktrace. bt ifNil: [ nil ] ifNotNil: [ bt printString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'entries add: (Array with: each asString with: fileName with: loadState with: assocOop with: persistentFile with: transientCached with: (persistentFile notNil) with: failureDetail with: retryDetail with: failureSource with: failureMessage with: lastAttemptedFile with: retrySource with: exceptionOop with: backtraceText) ] ]. '.
		stream nextPutAll: 'entries asArray ]' ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> autoloadFileFor: aConstantName [
	^ session executeScriptAndFetchObject: (self autoloadFileScriptFor: aConstantName)
]

{ #category : '*GemStone-GBS-MagLev' }
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
	result := session executeScriptAndFetchObject: self clearTransientAutoloadCacheScript.
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> clearTransientAutoloadCacheScript [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns | | tns cache | '.
		stream nextPutAll: 'ns ifNil: [ false ] ifNotNil: [ '.
		stream nextPutAll: 'tns := ((ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]). '.
		stream nextPutAll: 'cache := (tns notNil and: [ tns respondsTo: #autoloadCache ]) '.
		stream nextPutAll: 'ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'cache ifNil: [ false ] ifNotNil: [ '.
		stream nextPutAll: '[ (cache respondsTo: #removeAll) ifTrue: [ cache removeAll ] ] on: Error do: [ ]. '.
		stream nextPutAll: 'true ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression ]
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
	result := session executeScriptAndFetchObject: (self recoverAutoloadScriptFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> recoverAutoloadScriptFor: aConstantName [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name | | assoc fileName tns cache pns | '.
		stream nextPutAll: 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [ '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'fileName := assoc ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: '[ (assoc respondsTo: #fileName) ifTrue: [ assoc fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'tns := ((ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]). '.
		stream nextPutAll: 'cache := (tns notNil and: [ tns respondsTo: #autoloadCache ]) '.
		stream nextPutAll: 'ifTrue: [ [ tns autoloadCache ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: '(fileName isNil and: [ cache notNil ]) ifTrue: [ '.
		stream nextPutAll: '[ cache do: [ :cached | | cachedKey cachedValue | '.
		stream nextPutAll: 'cachedKey := [ cached key ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'cachedValue := [ cached value ] on: Error do: [ nil ]. '.
		stream nextPutAll: '((cachedKey = name asSymbol) or: [ cachedKey = name ]) ifTrue: [ '.
		stream nextPutAll: 'fileName ifNil: [ fileName := [ cachedValue fileName ] on: Error do: [ nil ] ] ] ] ] on: Error do: [ ] ]. '.
		stream nextPutAll: 'pns := tns ifNil: [ nil ] ifNotNil: [ '.
		stream nextPutAll: '[ (tns respondsTo: #persistCopy) ifTrue: [ tns persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: '(fileName isNil and: [ pns notNil ]) ifTrue: [ '.
		stream nextPutAll: 'fileName := [ (pns respondsTo: #rubyAutoloadFileFor:) ifTrue: [ pns rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'fileName ifNil: [ Error signal: ''Autoload file could not be recovered.'' ]. '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoload:file:) '.
		stream nextPutAll: 'ifTrue: [ ns rubyAutoload: name asSymbol file: fileName. fileName ] '.
		stream nextPutAll: 'ifFalse: [ Error signal: ''Namespace does not support Ruby autoload.'' ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString) ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> registerAutoload: aConstantName file: aFileName [
	| result |
	result := session executeScriptAndFetchObject: (self
		registerAutoloadScriptFor: aConstantName
		file: aFileName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
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

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> removeAutoload: aConstantName [
	| result |
	result := session executeScriptAndFetchObject: (self removeAutoloadScriptFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
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

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> requireFileNamed: aString [
	^ session rubyRuntime requireFileNamed: aString
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoload: aConstantName [
	| result |
	result := session executeScriptAndFetchObject: (self resetAutoloadScriptFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> resetAutoloadScriptFor: aConstantName [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name | '.
		stream nextPutAll: '| assoc fileName transient | '.
		stream nextPutAll: 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [ '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'fileName := assoc ifNil: [ nil ] ifNotNil: [ [ assoc fileName ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'fileName ifNil: [ '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoloadFileFor:) '.
		stream nextPutAll: 'ifTrue: [ fileName := [ ns rubyAutoloadFileFor: name asSymbol ] on: Error do: [ nil ] ] ]. '.
		stream nextPutAll: 'assoc ifNotNil: [ '.
		stream nextPutAll: '(ns respondsTo: #removeConst:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns removeConst: name asSymbol env: 1 ] on: Error do: [ ] ] '.
		stream nextPutAll: 'ifFalse: [ (ns respondsTo: #removeConst:) ifTrue: [ [ ns removeConst: name asSymbol ] on: Error do: [ ] ] ] ]. '.
		stream nextPutAll: 'transient := (ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: false ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'transient ifNotNil: [ '.
		stream nextPutAll: '(transient respondsTo: #removeKey:ifAbsent:) '.
		stream nextPutAll: 'ifTrue: [ [ transient removeKey: name asSymbol ifAbsent: [ ] ] on: Error do: [ ] ] ]. '.
		stream nextPutAll: 'fileName ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString) ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoload: aConstantName [
	| result |
	result := session executeScriptAndFetchObject: (self retryAutoloadScriptFor: aConstantName).
	self invalidate.
	^ result
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> retryAutoload: aConstantName usingSourceKind: aSourceKind [
	| result |
	result := session executeScriptAndFetchObject: (self
		retryAutoloadScriptFor: aConstantName
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
	^ String streamContents: [ :stream |
		stream nextPutAll: '[:ns :name :sourceKind | '.
		stream nextPutAll: '| assoc fileName currentFile transient transientStore cache transientFile persist fileWasReset selectedSource resetTransient | '.
		stream nextPutAll: 'ns ifNil: [ Error signal: ''Namespace not found.'' ] ifNotNil: [ '.
		stream nextPutAll: 'selectedSource := sourceKind ifNil: [ nil ] ifNotNil: [ sourceKind asString ]. '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'currentFile := assoc ifNil: [ nil ] ifNotNil: [ [ assoc fileName ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'transientStore := (ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'cache := (transientStore notNil and: [ transientStore respondsTo: #autoloadCache ]) '.
		stream nextPutAll: 'ifTrue: [ [ transientStore autoloadCache ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'transientFile := nil. '.
		stream nextPutAll: 'cache ifNotNil: [ [ cache do: [ :cached | | cachedKey cachedValue | '.
		stream nextPutAll: 'cachedKey := [ cached key ] on: Error do: [ nil ]. '.
		stream nextPutAll: 'cachedValue := [ cached value ] on: Error do: [ nil ]. '.
		stream nextPutAll: '((cachedKey = name asSymbol) or: [ cachedKey = name ]) ifTrue: [ '.
		stream nextPutAll: 'transientFile ifNil: [ transientFile := [ (cachedValue respondsTo: #fileName) ifTrue: [ cachedValue fileName ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ] ] ] on: Error do: [ ] ]. '.
		stream nextPutAll: 'persist := transientStore ifNil: [ nil ] ifNotNil: [ [ (transientStore respondsTo: #persistCopy) ifTrue: [ transientStore persistCopy ] ifFalse: [ nil ] ] on: Error do: [ nil ] ]. '.
		stream nextPutAll: 'persist ifNil: [ persist := (ns respondsTo: #persistCopy) ifTrue: [ [ ns persistCopy ] on: Error do: [ nil ] ] ifFalse: [ nil ] ]. '.
		stream nextPutAll: 'fileName := nil. '.
		stream nextPutAll: 'selectedSource = ''current'' ifTrue: [ fileName := currentFile ]. '.
		stream nextPutAll: 'selectedSource = ''transient-reset'' ifTrue: [ fileName := transientFile ]. '.
		stream nextPutAll: 'selectedSource = ''persistent'' ifTrue: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ]. '.
		stream nextPutAll: 'selectedSource = ''persistent-after-reset'' ifTrue: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ]. '.
		stream nextPutAll: 'fileName ifNil: [ fileName := currentFile ]. '.
		stream nextPutAll: 'fileName ifNil: [ fileName := transientFile ]. '.
		stream nextPutAll: 'fileName ifNil: [ fileName := persist ifNil: [ nil ] ifNotNil: [ [ (persist respondsTo: #rubyAutoloadFileFor:) ifTrue: [ persist rubyAutoloadFileFor: name asSymbol ] ifFalse: [ nil ] ] on: Error do: [ nil ] ] ]. '.
		stream nextPutAll: 'fileName ifNil: [ Error signal: ''Autoload registration is not recoverable.'' ]. '.
		stream nextPutAll: 'fileWasReset := false. '.
		stream nextPutAll: 'resetTransient := selectedSource = ''transient-reset'' or: [ selectedSource = ''persistent-after-reset'' ]. '.
		stream nextPutAll: 'assoc := (ns respondsTo: #rubyAutoloadAssociationAtOrNil:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns rubyAutoloadAssociationAtOrNil: name asSymbol env: 1 ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'assoc ifNotNil: [ '.
		stream nextPutAll: '(ns respondsTo: #removeConst:env:) '.
		stream nextPutAll: 'ifTrue: [ [ ns removeConst: name asSymbol env: 1 ] on: Error do: [ ] ] '.
		stream nextPutAll: 'ifFalse: [ (ns respondsTo: #removeConst:) ifTrue: [ [ ns removeConst: name asSymbol ] on: Error do: [ ] ] ]. '.
		stream nextPutAll: 'fileWasReset := true ]. '.
		stream nextPutAll: 'transient := (ns respondsTo: #transientNameSpaceForStore:) '.
		stream nextPutAll: 'ifTrue: [ [ ns transientNameSpaceForStore: false ] on: Error do: [ nil ] ] '.
		stream nextPutAll: 'ifFalse: [ nil ]. '.
		stream nextPutAll: 'resetTransient ifTrue: [ transient ifNotNil: [ '.
		stream nextPutAll: '(transient respondsTo: #removeKey:ifAbsent:) '.
		stream nextPutAll: 'ifTrue: [ [ transient removeKey: name asSymbol ifAbsent: [ ] ] on: Error do: [ ] ] ]. '.
		stream nextPutAll: 'fileWasReset := true ]. '.
		stream nextPutAll: '(ns respondsTo: #rubyAutoload:file:) '.
		stream nextPutAll: 'ifTrue: [ ns rubyAutoload: name asSymbol file: fileName ] '.
		stream nextPutAll: 'ifFalse: [ Error signal: ''Namespace does not support rubyAutoload:file:.'' ]. '.
		stream nextPutAll: 'Array with: fileName with: fileWasReset with: (selectedSource ifNil: [ ''auto'' ]) ] ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression.
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aConstantName asString).
		stream nextPutAll: ' value: '.
		stream nextPutAll: (session marshalArgumentToScript: aSourceKind) ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteNamespaceMirror >> supportsAutoload [
	^ session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream nextPutAll: '[:ns | '.
		stream nextPutAll: 'ns notNil and: [ ns respondsTo: #rubyAutoload:file: ]'.
		stream nextPutAll: '] value: '.
		stream nextPutAll: self namespaceExpression ])
]
