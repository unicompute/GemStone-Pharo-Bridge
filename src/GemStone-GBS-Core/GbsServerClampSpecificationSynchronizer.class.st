Class {
	#name : 'GbsServerClampSpecificationSynchronizer',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsServerClampSpecificationSynchronizer class >> clampSpecOopForScheme: aReplicationScheme session: aSession [
	(aReplicationScheme respondsTo: #hasServerClampMetadata) ifFalse: [ ^ nil ].
	aReplicationScheme hasServerClampMetadata ifFalse: [ ^ nil ].
	^ (self on: aSession) clampSpecOopForScheme: aReplicationScheme
]

{ #category : 'instance creation' }
GbsServerClampSpecificationSynchronizer class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbsServerClampSpecificationSynchronizer class >> resetForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionServerClampSpecificationCaches)
		removeKey: aSession
		ifAbsent: [ nil ]
]

{ #category : 'cache' }
GbsServerClampSpecificationSynchronizer >> cache [
	^ (session class weakRegistryNamed: #GbsSessionServerClampSpecificationCaches)
		at: session
		ifAbsentPut: [ IdentityDictionary new ]
]

{ #category : 'syncing' }
GbsServerClampSpecificationSynchronizer >> clampSpecOopForScheme: aReplicationScheme [
	| fingerprint entry oop |
	fingerprint := aReplicationScheme serverClampSpecificationFingerprint.
	entry := self cache at: aReplicationScheme ifAbsent: [ nil ].
	(entry notNil and: [ entry first = fingerprint ]) ifTrue: [ ^ entry second ].
	oop := self installClampSpecForScheme: aReplicationScheme.
	self cache at: aReplicationScheme put: { fingerprint. oop }.
	^ oop
]

{ #category : 'syncing' }
GbsServerClampSpecificationSynchronizer >> installClampSpecForScheme: aReplicationScheme [
	^ session
		returnRemoteCommandBody: self serverClampSpecificationScript
		literalBindings: (Dictionary new
			at: 'addSubleafHeaders' put: aReplicationScheme clamp addSubleafHeaders;
			at: 'classLevelEntries' put: aReplicationScheme serverClampInstVarLevelEntries;
			at: 'environmentId' put: aReplicationScheme clamp environmentId;
			at: 'instVarLevelsSelector' put: aReplicationScheme clamp instVarLevelsSelector;
			at: 'traversalCallBackSelector' put: aReplicationScheme clamp traversalCallBackSelector;
			yourself)
		oopBindings: Dictionary new
]

{ #category : 'scripts' }
GbsServerClampSpecificationSynchronizer >> serverClampSpecificationScript [
	^ '| spec instVarLevels identityMapClass classForName classObject |
identityMapClass := GsSession currentSession resolveSymbol: #FastIdentityKeyValueDictionary.
identityMapClass ifNil: [
	identityMapClass := GsSession currentSession resolveSymbol: #IdentityKeyValueDictionary ].
identityMapClass := identityMapClass
	ifNil: [ IdentityDictionary ]
	ifNotNil: [
		(identityMapClass respondsTo: #value)
			ifTrue: [ identityMapClass value ]
			ifFalse: [ identityMapClass ] ].
instVarLevels := identityMapClass new.
classForName := [ :className |
	| resolved |
	resolved := GsSession currentSession resolveSymbol: className asSymbol.
	resolved
		ifNil: [ nil ]
		ifNotNil: [
			(resolved respondsTo: #value)
				ifTrue: [ resolved value ]
				ifFalse: [ resolved ] ] ].
classLevelEntries do: [ :entry |
	classObject := classForName value: (entry at: 1).
	classObject ifNotNil: [ instVarLevels at: classObject put: (entry at: 2) ] ].
spec := ClampSpecification new.
(spec respondsTo: #idClamps:)
	ifTrue: [ spec idClamps: IdentitySet new ]
	ifFalse: [ spec instVarAt: 1 put: IdentitySet new ].
(spec respondsTo: #classClamps:)
	ifTrue: [ spec classClamps: IdentitySet new ]
	ifFalse: [ spec instVarAt: 2 put: IdentitySet new ].
(spec respondsTo: #instVarLevels:)
	ifTrue: [ spec instVarLevels: instVarLevels ]
	ifFalse: [ spec instVarAt: 3 put: instVarLevels ].
(spec respondsTo: #addSubleafHeaders:)
	ifTrue: [ spec addSubleafHeaders: addSubleafHeaders ]
	ifFalse: [ spec instVarAt: 4 put: addSubleafHeaders ].
(spec respondsTo: #instVarLevelsSelector:)
	ifTrue: [ spec instVarLevelsSelector: instVarLevelsSelector ]
	ifFalse: [ spec instVarAt: 5 put: instVarLevelsSelector ].
(spec respondsTo: #traversalCallBackSelector:)
	ifTrue: [ spec traversalCallBackSelector: traversalCallBackSelector ]
	ifFalse: [ spec instVarAt: 6 put: traversalCallBackSelector ].
(spec respondsTo: #valueClamps:)
	ifTrue: [ spec valueClamps: nil ]
	ifFalse: [ spec instVarAt: 7 put: nil ].
(spec respondsTo: #environmentId:)
	ifTrue: [ spec environmentId: environmentId ]
	ifFalse: [ spec instVarAt: 8 put: environmentId ].
spec'
]

{ #category : 'accessing' }
GbsServerClampSpecificationSynchronizer >> session [
	^ session
]

{ #category : 'accessing' }
GbsServerClampSpecificationSynchronizer >> session: aSession [
	session := aSession
]
