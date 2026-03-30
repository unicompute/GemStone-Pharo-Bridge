Class {
	#name : 'GbxReplicatorManager',
	#superclass : 'Object',
	#instVars : [
		'session',
		'serverMap',
		'clientMap',
		'needServerInstVarNames',
		'replicatorsNeedingServerInstVarNames',
		'clampManager'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxReplicatorManager class >> newForSession: aSession [
	^ self new
		initializeForSession: aSession;
		yourself
]

{ #category : 'mapping' }
GbxReplicatorManager >> atClient: clientBehavior put: aReplicator [
	clientMap at: clientBehavior put: aReplicator.
	^ aReplicator
]

{ #category : 'mapping' }
GbxReplicatorManager >> atClient: clientBehavior andServer: serverBehavior put: aReplicator [
	self atClient: clientBehavior put: aReplicator.
	serverMap at: serverBehavior put: aReplicator.
	^ aReplicator
]

{ #category : 'accessing' }
GbxReplicatorManager >> clampManager [
	^ clampManager
]

{ #category : 'accessing' }
GbxReplicatorManager >> clientMap [
	^ clientMap
]

{ #category : 'accessing' }
GbxReplicatorManager >> currentReplicators [
	^ clientMap values
]

{ #category : 'accessing' }
GbxReplicatorManager >> defaultReplicatorClass [
	^ GbxObjectReplicator
]

{ #category : 'initialization' }
GbxReplicatorManager >> initializeForSession: aSession [
	session := aSession.
	serverMap := IdentityDictionary new.
	clientMap := GbxClientObjDictionary classWithStats new: 300.
	needServerInstVarNames := false.
	replicatorsNeedingServerInstVarNames := OrderedCollection new.
	clampManager := self newClampManagerFor: aSession.
	GBSM clientMap: clientMap
]

{ #category : 'private' }
GbxReplicatorManager >> newClampManagerFor: aSession [
	| clampClass |
	aSession ifNil: [ ^ nil ].
	(aSession respondsTo: #clampManagerClass) ifFalse: [ ^ nil ].
	clampClass := aSession clampManagerClass.
	(clampClass respondsTo: #forManager:)
		ifTrue: [ ^ clampClass forManager: self ].
	^ nil
]

{ #category : 'accessing' }
GbxReplicatorManager >> numberOfReplicators [
	^ clientMap size
]

{ #category : 'mapping' }
GbxReplicatorManager >> removeReplicatorForClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	| clientReplicator serverReplicator |
	clientReplicator := clientMap removeKey: clientBehavior ifAbsent: [ nil ].
	serverReplicator := serverMap removeKey: serverBehavior ifAbsent: [ nil ].
	(clampManager notNil and: [ clampManager respondsTo: #removeClampsForReplicator: ])
		ifTrue: [ clientReplicator ifNotNil: [ clampManager removeClampsForReplicator: clientReplicator ] ].
	^ clientReplicator ifNil: [ serverReplicator ]
]

{ #category : 'mapping' }
GbxReplicatorManager >> removeReplicatorForServerBehavior: serverBehavior [
	^ serverMap removeKey: serverBehavior ifAbsent: [ nil ]
]

{ #category : 'lookup' }
GbxReplicatorManager >> replicatorForClientBehavior: aBehavior ifAbsent: aBlock [
	^ clientMap at: aBehavior ifAbsent: aBlock
]

{ #category : 'accessing' }
GbxReplicatorManager >> replicatorRegistry [
	| registry |
	registry := Dictionary new.
	clientMap keysAndValuesDo: [ :behavior :replicator |
		registry at: behavior name asString put: replicator class ].
	^ registry
]

{ #category : 'lookup' }
GbxReplicatorManager >> replicatorForServerBehavior: aBehavior ifAbsent: aBlock [
	^ serverMap at: aBehavior ifAbsent: aBlock
]

{ #category : 'lookup' }
GbxReplicatorManager >> replicatorForServerBehavior: aBehavior ifAbsentPut: aBlock [
	^ serverMap at: aBehavior ifAbsent: [
		| replicator |
		replicator := aBlock value.
		serverMap at: aBehavior put: replicator.
		replicator ]
]

{ #category : 'deferred updates' }
GbxReplicatorManager >> serverInstVarNamesNeededByReplicator: aReplicator [
	replicatorsNeedingServerInstVarNames add: aReplicator.
	needServerInstVarNames := true
]

{ #category : 'accessing' }
GbxReplicatorManager >> session [
	^ session
]

{ #category : 'deferred updates' }
GbxReplicatorManager >> updateInstVarNamesAndClamps [
	needServerInstVarNames ifFalse: [ ^ self ].
	replicatorsNeedingServerInstVarNames do: [ :replicator |
		(replicator respondsTo: #fetchMissingServerInstVarNames)
			ifTrue: [ replicator fetchMissingServerInstVarNames ] ].
	(clampManager notNil and: [ clampManager respondsTo: #updateClampsForReplicators: ])
		ifTrue: [ clampManager updateClampsForReplicators: replicatorsNeedingServerInstVarNames ].
	replicatorsNeedingServerInstVarNames := OrderedCollection new.
	needServerInstVarNames := false
]
