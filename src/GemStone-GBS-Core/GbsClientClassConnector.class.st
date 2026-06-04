Class {
	#name : 'GbsClientClassConnector',
	#superclass : 'Object',
	#instVars : [
		'clientBehavior',
		'clientBehaviorName',
		'serverBehavior',
		'serverBehaviorName',
		'includeSubclasses',
		'serverInstVarNames',
		'replicationSpec',
		'replicatorClass'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsClientClassConnector class >> client: clientClassOrName server: serverClassOrName [
	^ self new
		clientBehavior: clientClassOrName;
		serverBehavior: serverClassOrName;
		yourself
]

{ #category : 'instance creation' }
GbsClientClassConnector class >> client: clientClassOrName server: serverClassOrName replicationSpec: aReplicationSpec serverInstVarNames: instVarNames [
	^ (self client: clientClassOrName server: serverClassOrName)
		replicationSpec: aReplicationSpec;
		serverInstVarNames: instVarNames;
		yourself
]

{ #category : 'accessing' }
GbsClientClassConnector >> clientBehavior [
	^ clientBehavior
]

{ #category : 'accessing' }
GbsClientClassConnector >> clientBehavior: aClassOrName [
	clientBehavior := aClassOrName
]

{ #category : 'accessing' }
GbsClientClassConnector >> clientBehaviorName [
	^ clientBehaviorName ifNil: [ self nameForBehavior: clientBehavior ]
]

{ #category : 'accessing' }
GbsClientClassConnector >> clientBehaviorName: aString [
	clientBehaviorName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'installing' }
GbsClientClassConnector >> installInReplicatorManager: aReplicatorManager [
	| replicator session clientBehaviors |
	aReplicatorManager ifNil: [ ^ nil ].
	session := aReplicatorManager session.
	clientBehaviors := self resolvedClientBehaviors.
	self removeConflictingReplicatorsIn: aReplicatorManager.
	replicator := self newReplicatorFor: aReplicatorManager.
	self configureReplicator: replicator manager: aReplicatorManager.
	aReplicatorManager
		atClient: self resolvedClientBehavior
		andServer: self resolvedServerBehavior
		put: replicator.
	self
		registerClientAliases: clientBehaviors
		forReplicator: replicator
		in: aReplicatorManager.
	self registerConnectorStateIn: aReplicatorManager.
	self
		updateClampMetadataIn: aReplicatorManager
		forReplicator: replicator.
	self markDeferredServerInstVarUpdateFor: replicator in: aReplicatorManager.
	^ replicator
]

{ #category : 'accessing' }
GbsClientClassConnector >> includeSubclasses [
	^ includeSubclasses == true
]

{ #category : 'accessing' }
GbsClientClassConnector >> includeSubclasses: aBoolean [
	includeSubclasses := aBoolean == true
]

{ #category : 'private' }
GbsClientClassConnector >> addReplicator: aReplicator toConflictList: conflicts [
	aReplicator ifNil: [ ^ conflicts ].
	(conflicts anySatisfy: [ :each | each == aReplicator ])
		ifFalse: [ conflicts add: aReplicator ].
	^ conflicts
]

{ #category : 'private' }
GbsClientClassConnector >> configureReplicator: aReplicator manager: aReplicatorManager [
	(aReplicator respondsTo: #manager:) ifTrue: [
		aReplicator manager: aReplicatorManager ].
	(aReplicator respondsTo: #session:) ifTrue: [
		aReplicator session: aReplicatorManager session ].
	(aReplicator respondsTo: #clientClass:) ifTrue: [
		aReplicator clientClass: self resolvedClientBehavior ].
	(aReplicator respondsTo: #serverClass:) ifTrue: [
		aReplicator serverClass: self resolvedServerBehavior ].
	((aReplicator respondsTo: #serverInstVarNames:)
		and: [ self serverInstVarNames isEmpty not ]) ifTrue: [
			aReplicator serverInstVarNames: self serverInstVarNames ].
	^ aReplicator
]

{ #category : 'private' }
GbsClientClassConnector >> markDeferredServerInstVarUpdateFor: aReplicator in: aReplicatorManager [
	((replicationSpec notNil and: [ replicationSpec ~= #callback ])
		and: [ self serverInstVarNames isEmpty
		and: [ aReplicatorManager respondsTo: #markServerInstVarNamesNeededByReplicator: ] ]) ifTrue: [
			aReplicatorManager markServerInstVarNamesNeededByReplicator: aReplicator ]
]

{ #category : 'private' }
GbsClientClassConnector >> nameForBehavior: aBehaviorOrName [
	aBehaviorOrName ifNil: [ ^ '' ].
	(aBehaviorOrName respondsTo: #name) ifTrue: [
		^ aBehaviorOrName name asString ].
	^ aBehaviorOrName asString
]

{ #category : 'private' }
GbsClientClassConnector >> newReplicatorFor: aReplicatorManager [
	| class |
	class := replicatorClass ifNil: [
		(aReplicatorManager respondsTo: #replicatorClassForClientBehavior:)
			ifTrue: [ aReplicatorManager replicatorClassForClientBehavior: self resolvedClientBehavior ]
			ifFalse: [
				(aReplicatorManager respondsTo: #defaultReplicatorClass)
					ifTrue: [ aReplicatorManager defaultReplicatorClass ]
					ifFalse: [ GbxObjectReplicator ] ] ].
	^ class new
]

{ #category : 'private' }
GbsClientClassConnector >> removeConflictingReplicatorsIn: aReplicatorManager [
	| conflicts server |
	(aReplicatorManager respondsTo: #removeReplicator:) ifFalse: [ ^ self ].
	conflicts := OrderedCollection new.
	server := self resolvedServerBehavior.
	(aReplicatorManager respondsTo: #replicatorForClientBehavior:ifAbsent:) ifTrue: [
		self resolvedClientBehaviors do: [ :client |
			(aReplicatorManager
			replicatorForClientBehavior: client
			ifAbsent: [ nil ]) ifNotNil: [ :replicator |
				self addReplicator: replicator toConflictList: conflicts ] ] ].
	(server notNil and: [ aReplicatorManager respondsTo: #replicatorForServerBehavior:ifAbsent: ])
		ifTrue: [
			(aReplicatorManager
			replicatorForServerBehavior: server
			ifAbsent: [ nil ]) ifNotNil: [ :replicator |
				self addReplicator: replicator toConflictList: conflicts ] ].
	conflicts do: [ :replicator |
		self unregisterConnectorPairForReplicator: replicator manager: aReplicatorManager.
		aReplicatorManager removeReplicator: replicator ].
	^ self
]

{ #category : 'private' }
GbsClientClassConnector >> registerClientAliases: clientBehaviors forReplicator: aReplicator in: aReplicatorManager [
	clientBehaviors do: [ :clientBehavior |
		clientBehavior == self resolvedClientBehavior ifFalse: [
			aReplicatorManager
				atClient: clientBehavior
				put: aReplicator ] ].
	^ aReplicator
]

{ #category : 'private' }
GbsClientClassConnector >> registerConnectorStateIn: aReplicatorManager [
	| session sessionKey |
	session := aReplicatorManager session.
	sessionKey := GbsSessionManager sessionKeyForSessionObject: session.
	session
		ifNil: [
			GbsSessionManager
				addConnectorClient: self clientBehaviorName
				server: self serverBehaviorName ]
		ifNotNil: [
			GbsSessionManager
				addConnectorClient: self clientBehaviorName
				server: self serverBehaviorName
				forSession: session ].
	GbsSessionManager
		setConnectorClient: self clientBehaviorName
		server: self serverBehaviorName
		connected: true
		inSession: sessionKey.
	^ self
]

{ #category : 'accessing' }
GbsClientClassConnector >> replicationSpec [
	^ replicationSpec
]

{ #category : 'accessing' }
GbsClientClassConnector >> replicationSpec: aReplicationSpec [
	replicationSpec := ((aReplicationSpec isCollection and: [ aReplicationSpec isEmpty ])
		ifTrue: [ nil ]
		ifFalse: [ aReplicationSpec ])
]

{ #category : 'accessing' }
GbsClientClassConnector >> replicatorClass [
	^ replicatorClass
]

{ #category : 'accessing' }
GbsClientClassConnector >> replicatorClass: aClass [
	replicatorClass := aClass
]

{ #category : 'private' }
GbsClientClassConnector >> resolvedClientBehavior [
	^ self resolvedBehaviorFrom: clientBehavior
]

{ #category : 'private' }
GbsClientClassConnector >> resolvedClientBehaviors [
	| primary behaviors |
	primary := self resolvedClientBehavior.
	primary ifNil: [ ^ #() ].
	behaviors := OrderedCollection with: primary.
	self includeSubclasses ifTrue: [
		(primary respondsTo: #allSubclasses) ifTrue: [
			primary allSubclasses do: [ :subclass |
				(behaviors anySatisfy: [ :each | each == subclass ])
					ifFalse: [ behaviors add: subclass ] ] ] ].
	^ behaviors asArray
]

{ #category : 'private' }
GbsClientClassConnector >> resolvedServerBehavior [
	^ self resolvedBehaviorFrom: serverBehavior
]

{ #category : 'private' }
GbsClientClassConnector >> resolvedBehaviorFrom: aBehaviorOrName [
	aBehaviorOrName ifNil: [ ^ nil ].
	(aBehaviorOrName respondsTo: #name) ifTrue: [ ^ aBehaviorOrName ].
	^ Smalltalk globals
		at: aBehaviorOrName asString asSymbol
		ifAbsent: [ aBehaviorOrName ]
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverBehavior [
	^ serverBehavior
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverBehavior: aClassOrName [
	serverBehavior := aClassOrName
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverBehaviorName [
	^ serverBehaviorName ifNil: [ self nameForBehavior: serverBehavior ]
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverBehaviorName: aString [
	serverBehaviorName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverInstVarNames [
	^ serverInstVarNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsClientClassConnector >> serverInstVarNames: aCollection [
	serverInstVarNames := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'private' }
GbsClientClassConnector >> unregisterConnectorPairForReplicator: aReplicator manager: aReplicatorManager [
	| session clientName serverName |
	clientName := (aReplicator respondsTo: #clientClass)
		ifTrue: [ self nameForBehavior: aReplicator clientClass ]
		ifFalse: [ '' ].
	serverName := (aReplicator respondsTo: #serverClass)
		ifTrue: [ self nameForBehavior: aReplicator serverClass ]
		ifFalse: [ '' ].
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ self ].
	session := aReplicatorManager session.
	session
		ifNil: [
			GbsSessionManager
				removeConnectorClient: clientName
				server: serverName ]
		ifNotNil: [
			GbsSessionManager
				removeConnectorClient: clientName
				server: serverName
				forSession: session ].
	^ self
]

{ #category : 'private' }
GbsClientClassConnector >> updateClampMetadataIn: aReplicatorManager [
	^ self
		updateClampMetadataIn: aReplicatorManager
		forReplicator: nil
]

{ #category : 'private' }
GbsClientClassConnector >> updateClampMetadataIn: aReplicatorManager forReplicator: aReplicator [
	| scheme clientClass |
	replicationSpec ifNil: [ ^ self ].
	(aReplicatorManager respondsTo: #currentReplicationScheme) ifFalse: [ ^ self ].
	scheme := [ aReplicatorManager currentReplicationScheme ]
		on: Error
		do: [ nil ].
	scheme ifNil: [ ^ self ].
	replicationSpec = #callback ifTrue: [
		scheme
			updateForClampingByCallback: true
			inSession: aReplicatorManager session
			serverBehavior: self resolvedServerBehavior.
		^ self ].
	clientClass := self resolvedClientBehavior.
	clientClass ifNil: [ ^ self ].
	(aReplicator notNil and: [
		(aReplicator respondsTo: #usesInstVarMap)
			and: [ aReplicator usesInstVarMap ] ]) ifTrue: [
		^ scheme
			updateInstVarLevelsForClass: clientClass
			serverInstVarNames: self serverInstVarNames
			serverToClientOffsets: aReplicator serverToClientOffsets
			replicationSpec: replicationSpec ].
	^ scheme
		updateInstVarLevelsForClass: clientClass
		serverInstVarNames: self serverInstVarNames
		replicationSpec: replicationSpec
]

{ #category : 'class updating' }
GbsClientClassConnector >> updateSTInSession: aSession [
	| clientName serverName |
	clientName := self clientBehaviorName.
	serverName := self serverBehaviorName.
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [
		self error: 'Client and server behavior names are required for client-class generation.' ].
	^ GbsSessionManager
		generateTypedWrapperForClient: clientName
		server: serverName
		forSession: aSession
]

{ #category : 'class updating' }
GbsClientClassConnector >> updateGSInSession: aSession [
	aSession ifNil: [ self error: 'A GemStone session is required for server-class generation.' ].
	^ aSession executeScriptAndReturnOop: self updateGSScript
]

{ #category : 'class updating' }
GbsClientClassConnector >> updateGSScript [
	| className instVars |
	className := self serverBehaviorName.
	className isEmpty ifTrue: [
		self error: 'A server behavior name is required for server-class generation.' ].
	instVars := self serverInstVarNames.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| class className instVars |';
			cr;
			nextPutAll: 'className := ';
			nextPutAll: className printString;
			nextPutAll: ' asSymbol.';
			cr;
			nextPutAll: 'instVars := ';
			nextPutAll: instVars printString;
			nextPutAll: '.';
			cr;
			nextPutAll: 'class := GsSession currentSession resolveSymbol: className.';
			cr;
			nextPutAll: 'class ifNil: [ class := Object subclass: className instVarNames: instVars classVars: #() classInstVars: #() poolDictionaries: #() inDictionary: UserGlobals ].';
			cr;
			nextPutAll: 'class asOop' ]
]

{ #category : 'class updating' }
GbsClientClassConnector >> versionStatusForClientVersion: clientVersion serverVersion: serverVersion [
	(clientVersion isNil or: [ serverVersion isNil ]) ifTrue: [ ^ #unknown ].
	^ clientVersion = serverVersion
		ifTrue: [ #matched ]
		ifFalse: [ #mismatch ]
]

{ #category : 'class updating' }
GbsClientClassConnector >> verifyClassVersionsInSession: aSession [
	| clientClass serverName serverMirror clientVersion serverVersion status |
	clientClass := self resolvedClientBehavior.
	serverName := self serverBehaviorName.
	clientVersion := (clientClass notNil and: [ clientClass respondsTo: #classVersion ])
		ifTrue: [ [ clientClass classVersion ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	serverMirror := (aSession notNil and: [ serverName isEmpty not ])
		ifTrue: [ [ aSession classMirrorOfNamed: serverName ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	serverVersion := serverMirror ifNil: [ nil ] ifNotNil: [
		[ serverMirror version ] on: Error do: [ nil ] ].
	status := self
		versionStatusForClientVersion: clientVersion
		serverVersion: serverVersion.
	^ Dictionary new
		at: #client put: self clientBehaviorName;
		at: #server put: serverName;
		at: #clientVersion put: clientVersion;
		at: #serverVersion put: serverVersion;
		at: #versionStatus put: status;
		at: #needsUpdate put: status = #mismatch;
		at: #versionMatches put: status ~= #mismatch;
		yourself
]
