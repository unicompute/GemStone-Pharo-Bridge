Class {
	#name : 'GbsClientClassConnector',
	#superclass : 'Object',
	#instVars : [
		'clientBehavior',
		'clientBehaviorName',
		'serverBehavior',
		'serverBehaviorName',
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
	| replicator session |
	aReplicatorManager ifNil: [ ^ nil ].
	session := aReplicatorManager session.
	replicator := self newReplicatorFor: aReplicatorManager.
	self configureReplicator: replicator manager: aReplicatorManager.
	aReplicatorManager
		atClient: self resolvedClientBehavior
		andServer: self resolvedServerBehavior
		put: replicator.
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
	self updateClampMetadataIn: aReplicatorManager.
	self markDeferredServerInstVarUpdateFor: replicator in: aReplicatorManager.
	^ replicator
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
GbsClientClassConnector >> updateClampMetadataIn: aReplicatorManager [
	| scheme clientClass |
	replicationSpec ifNil: [ ^ self ].
	(aReplicatorManager respondsTo: #currentReplicationScheme) ifFalse: [ ^ self ].
	scheme := [ aReplicatorManager currentReplicationScheme ]
		on: Error
		do: [ nil ].
	scheme ifNil: [ ^ self ].
	replicationSpec = #callback ifTrue: [
		scheme updateForClampingByCallback: true inSession: aReplicatorManager session.
		^ self ].
	clientClass := self resolvedClientBehavior.
	clientClass ifNil: [ ^ self ].
	scheme
		updateInstVarLevelsForClass: clientClass
		serverInstVarNames: self serverInstVarNames
		replicationSpec: replicationSpec
]
