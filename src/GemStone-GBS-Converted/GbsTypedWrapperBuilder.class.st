Class {
	#name : 'GbsTypedWrapperBuilder',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> generateWrapperForClient: clientClassName server: serverClassName [
	^ self
		generateWrapperForClient: clientClassName
		server: serverClassName
		session: GbsSessionParameters currentSession
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> generateWrapperForClient: clientClassName server: serverClassName session: aSession [
	| clientName serverName className wrapperClass |
	clientName := self normalizedConnectorName: clientClassName fallback: 'AnonymousClient'.
	serverName := self normalizedConnectorName: serverClassName fallback: 'AnonymousServer'.
	className := self wrapperClassNameForClient: clientName server: serverName.
	wrapperClass := Smalltalk globals at: className ifAbsent: [ nil ].
	wrapperClass ifNotNil: [
		(wrapperClass inheritsFrom: GbsTypedProxy)
			ifFalse: [ self error: className asString , ' already exists and is not a GbsTypedProxy subclass.' ].
		self
			installMetadataMethodsOn: wrapperClass
			client: clientName
			server: serverName
			session: aSession.
		self
			installForwardingMethodsOn: wrapperClass
			client: clientName
			server: serverName
			session: aSession.
		^ wrapperClass ].
	Smalltalk classInstaller make: [ :builder |
		builder
			superclass: GbsTypedProxy;
			name: className;
			slots: #();
			package: 'GemStone-GBS-Converted' ].
	wrapperClass := Smalltalk globals at: className.
	self
		installMetadataMethodsOn: wrapperClass
		client: clientName
		server: serverName
		session: aSession.
	self
		installForwardingMethodsOn: wrapperClass
		client: clientName
		server: serverName
		session: aSession.
	^ wrapperClass
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> compileForwardingSelector: aSelector on: wrapperClass [
	wrapperClass
		compile: (self forwardingMethodSourceFor: aSelector)
		classified: 'generated forwarding'
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> forwardingArgumentNamesFor: aSelector [
	^ (1 to: aSelector numArgs) collect: [ :index | 'arg', index printString ]
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> forwardingHeaderFor: aSelector [
	| argNames |
	argNames := self forwardingArgumentNamesFor: aSelector.
	aSelector numArgs = 0 ifTrue: [ ^ aSelector asString ].
	aSelector isBinary ifTrue: [ ^ aSelector asString, ' ', argNames first ].
	^ String streamContents: [ :stream |
		aSelector keywords withIndexDo: [ :keyword :index |
			index > 1 ifTrue: [ stream space ].
			stream
				nextPutAll: keyword;
				space;
				nextPutAll: (argNames at: index) ] ]
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> forwardingMethodSourceFor: aSelector [
	| header argNames argumentArraySource |
	header := self forwardingHeaderFor: aSelector.
	argNames := self forwardingArgumentNamesFor: aSelector.
	argumentArraySource := argNames isEmpty
		ifTrue: [ '#()' ]
		ifFalse: [
			String streamContents: [ :stream |
				stream nextPutAll: '{ '.
				argNames withIndexDo: [ :each :index |
					index > 1 ifTrue: [ stream nextPutAll: '. ' ].
					stream nextPutAll: each ].
				stream nextPutAll: ' }' ] ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: header;
			cr;
			tab;
			nextPutAll: '^ self forwardGeneratedRemoteSelector: ';
			nextPutAll: aSelector storeString;
			nextPutAll: ' arguments: ';
			nextPutAll: argumentArraySource ]
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> forwardingSelectorsForClientBehavior: aBehavior wrapperClass: wrapperClass [
	| selectors seen hierarchy |
	aBehavior ifNil: [ ^ #() ].
	selectors := OrderedCollection new.
	seen := Set new.
	hierarchy := aBehavior withAllSuperclasses reject: [ :each |
		each == Object or: [ each == ProtoObject ] ].
	hierarchy reverseDo: [ :behavior |
		((behavior methodDict keys)
			asSortedCollection: [ :left :right | left asString <= right asString ])
			do: [ :selector |
				(seen includes: selector) ifFalse: [
					seen add: selector.
					(self shouldGenerateForwardingSelector: selector on: wrapperClass) ifTrue: [
						selectors add: selector ] ] ] ].
	^ selectors asArray
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> forwardingSpecificationForClient: clientName server: serverName session: aSession wrapperClass: wrapperClass [
	| remoteSpecification remoteSelectors |
	remoteSpecification := self
		remoteForwardingSpecificationForServer: serverName
		session: aSession
		wrapperClass: wrapperClass.
	remoteSelectors := remoteSpecification at: #selectors ifAbsent: [ #() ].
	remoteSelectors ifNotEmpty: [ ^ remoteSpecification ].
	^ self
		clientForwardingSpecificationForClient: clientName
		wrapperClass: wrapperClass
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> clientForwardingSpecificationForClient: clientName wrapperClass: wrapperClass [
	| clientBehavior selectors |
	clientBehavior := Smalltalk globals at: clientName asSymbol ifAbsent: [ nil ].
	selectors := self
		forwardingSelectorsForClientBehavior: clientBehavior
		wrapperClass: wrapperClass.
	^ {
		#selectors -> selectors.
		#protocols -> #().
		#source -> #client
	} asDictionary
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> installForwardingMethodsOn: wrapperClass client: clientName server: serverName session: aSession [
	| specification selectors |
	specification := self
		forwardingSpecificationForClient: clientName
		server: serverName
		session: aSession
		wrapperClass: wrapperClass.
	selectors := specification at: #selectors ifAbsent: [ #() ].
	self
		removeGeneratedForwardingMethodsFrom: wrapperClass
		except: selectors.
	selectors do: [ :selector |
		self compileForwardingSelector: selector on: wrapperClass ].
	self
		installGeneratedForwardingMetadataOn: wrapperClass
		selectors: selectors
		protocols: (specification at: #protocols ifAbsent: [ #() ])
		source: (specification at: #source ifAbsent: [ #client ])
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> installGeneratedForwardingMetadataOn: wrapperClass selectors: selectors protocols: protocolEntries source: aSymbol [
	wrapperClass class
		compile: 'generatedForwardingSelectors
	^ ', selectors storeString
		classified: 'generated metadata'.
	wrapperClass class
		compile: 'generatedForwardingProtocols
	^ ', protocolEntries storeString
		classified: 'generated metadata'.
	wrapperClass class
		compile: 'generatedForwardingSource
	^ ', aSymbol storeString
		classified: 'generated metadata'
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> installMetadataMethodsOn: wrapperClass client: clientName server: serverName session: aSession [
	| remoteMirror remoteVersion remoteCount |
	wrapperClass class
		compile: 'clientBehaviorName
	^ ', clientName storeString
		classified: 'generated metadata'.
	wrapperClass class
		compile: 'serverBehaviorName
	^ ', serverName storeString
		classified: 'generated metadata'.
	remoteMirror := [ aSession ifNil: [ nil ] ifNotNil: [ GbsRemoteClassMirror on: aSession class: serverName ] ]
		on: Error
		do: [ nil ].
	remoteVersion := [ remoteMirror ifNil: [ nil ] ifNotNil: [ remoteMirror version ] ]
		on: Error
		do: [ nil ].
	remoteCount := [ remoteMirror ifNil: [ nil ] ifNotNil: [ remoteMirror numberOfVersions ] ]
		on: Error
		do: [ nil ].
	wrapperClass class
		compile: 'serverBehaviorVersion
	^ ', remoteVersion storeString
		classified: 'generated metadata'.
	wrapperClass class
		compile: 'serverBehaviorNumberOfVersions
	^ ', remoteCount storeString
		classified: 'generated metadata'
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> normalizedConnectorName: aValue fallback: fallbackString [
	| normalized |
	normalized := aValue
		ifNil: [ '' ]
		ifNotNil: [ aValue asString trimBoth ].
	normalized isEmpty ifTrue: [ ^ fallbackString ].
	^ normalized
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> sanitizeNameComponent: aString [
	| raw sanitized |
	raw := self normalizedConnectorName: aString fallback: 'Anonymous'.
	sanitized := String streamContents: [ :stream |
		raw do: [ :each |
			(each isAlphaNumeric or: [ each = $_ ])
				ifTrue: [ stream nextPut: each ]
				ifFalse: [ stream nextPut: $_ ] ] ].
	sanitized ifEmpty: [ ^ 'Anonymous' ].
	(sanitized first isDigit)
		ifTrue: [ ^ 'N', sanitized ].
	^ sanitized
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> removeGeneratedForwardingMethodsFrom: wrapperClass except: selectorsToKeep [
	| keepSet |
	keepSet := selectorsToKeep asSet.
	wrapperClass methodDict keys do: [ :selector |
		(self methodProtocolNameFor: selector on: wrapperClass) = 'generated forwarding'
				ifTrue: [
					(keepSet includes: selector) ifFalse: [
						wrapperClass removeSelector: selector ] ] ]
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> remoteForwardingSpecificationForServer: serverName session: aSession wrapperClass: wrapperClass [
	| mirror protocolEntries selectors |
	aSession ifNil: [ ^ self emptyForwardingSpecification ].
	mirror := [ GbsRemoteClassMirror on: aSession class: serverName ]
		on: Error
		do: [ ^ self emptyForwardingSpecification ].
	protocolEntries := [ mirror instanceProtocols ]
		on: Error
		do: [ ^ self emptyForwardingSpecification ].
	protocolEntries ifNil: [ ^ self emptyForwardingSpecification ].
	selectors := self
		selectorSymbolsFromProtocolEntries: protocolEntries
		wrapperClass: wrapperClass.
	^ {
		#selectors -> selectors.
		#protocols -> protocolEntries.
		#source -> #remote
	} asDictionary
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> emptyForwardingSpecification [
	^ {
		#selectors -> #().
		#protocols -> #().
		#source -> #client
	} asDictionary
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> selectorSymbolsFromProtocolEntries: protocolEntries wrapperClass: wrapperClass [
	| selectors |
	selectors := OrderedCollection new.
	protocolEntries do: [ :entry |
		(entry at: 2 ifAbsent: [ #() ]) do: [ :each |
			| selector |
			selector := each asString asSymbol.
			(self shouldGenerateForwardingSelector: selector on: wrapperClass) ifTrue: [
				selectors add: selector ] ] ].
	^ selectors asArray
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> methodProtocolNameFor: aSelector on: wrapperClass [
	| protocol |
	protocol := ((wrapperClass >> aSelector) respondsTo: #protocol)
		ifTrue: [ (wrapperClass >> aSelector) protocol ]
		ifFalse: [ nil ].
	protocol ifNil: [ ^ '' ].
	(protocol respondsTo: #name) ifTrue: [ ^ protocol name asString ].
	^ protocol asString
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> shouldGenerateForwardingSelector: aSelector on: wrapperClass [
	| localMethod protocol |
	(wrapperClass canUnderstand: aSelector) ifFalse: [ ^ true ].
	localMethod := wrapperClass methodDict at: aSelector ifAbsent: [ nil ].
	localMethod ifNil: [ ^ false ].
	protocol := self methodProtocolNameFor: aSelector on: wrapperClass.
	^ protocol = 'generated forwarding'
]

{ #category : 'generation' }
GbsTypedWrapperBuilder class >> wrapperClassNameForClient: clientClassName server: serverClassName [
	^ ('GbsTypedProxy__',
		(self sanitizeNameComponent: clientClassName),
		'__',
		(self sanitizeNameComponent: serverClassName)) asSymbol
]
