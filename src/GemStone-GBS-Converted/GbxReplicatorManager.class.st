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
GbxReplicatorManager >> clientBehaviorsForReplicator: aReplicator [
	| behaviors |
	behaviors := OrderedCollection new.
	clientMap keysAndValuesDo: [ :behavior :replicator |
		replicator == aReplicator ifTrue: [ behaviors add: behavior ] ].
	^ behaviors asArray
]

{ #category : 'accessing' }
GbxReplicatorManager >> currentReplicators [
	| replicators |
	replicators := OrderedCollection new.
	clientMap values do: [ :replicator |
		(replicators anySatisfy: [ :each | each == replicator ])
			ifFalse: [ replicators add: replicator ] ].
	^ replicators asArray
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
	^ self currentReplicators size
]

{ #category : 'mapping' }
GbxReplicatorManager >> removeReplicatorForClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	| clientReplicator serverReplicator replicator |
	clientReplicator := clientMap at: clientBehavior ifAbsent: [ nil ].
	serverReplicator := serverMap at: serverBehavior ifAbsent: [ nil ].
	replicator := clientReplicator ifNil: [ serverReplicator ].
	replicator ifNil: [
		clientMap removeKey: clientBehavior ifAbsent: [ ].
		serverMap removeKey: serverBehavior ifAbsent: [ ].
		(self respondsTo: #unregisterConnectorPairForClientBehavior:serverBehavior:)
			ifTrue: [
				self
					unregisterConnectorPairForClientBehavior: clientBehavior
					serverBehavior: serverBehavior ].
		^ nil ].
	^ self removeReplicator: replicator
]

{ #category : 'mapping' }
GbxReplicatorManager >> removeReplicator: aReplicator [
	| clientBehaviors serverBehaviors |
	aReplicator ifNil: [ ^ nil ].
	clientBehaviors := self clientBehaviorsForReplicator: aReplicator.
	serverBehaviors := self serverBehaviorsForReplicator: aReplicator.
	clientBehaviors do: [ :behavior |
		clientMap removeKey: behavior ifAbsent: [ ] ].
	serverBehaviors do: [ :behavior |
		serverMap removeKey: behavior ifAbsent: [ ] ].
	self removeDeferredServerInstVarUpdateFor: aReplicator.
	(clampManager notNil and: [ clampManager respondsTo: #removeClampsForReplicator: ])
		ifTrue: [ clampManager removeClampsForReplicator: aReplicator ].
	(self respondsTo: #unregisterConnectorPairsForClientBehaviors:serverBehaviors:)
		ifTrue: [
			self
				unregisterConnectorPairsForClientBehaviors: clientBehaviors
				serverBehaviors: serverBehaviors ].
	^ aReplicator
]

{ #category : 'deferred updates' }
GbxReplicatorManager >> removeDeferredServerInstVarUpdateFor: aReplicator [
	replicatorsNeedingServerInstVarNames :=
		(replicatorsNeedingServerInstVarNames reject: [ :each | each == aReplicator ])
			asOrderedCollection.
	needServerInstVarNames := replicatorsNeedingServerInstVarNames isEmpty not
]

{ #category : 'mapping' }
GbxReplicatorManager >> removeReplicatorForServerBehavior: serverBehavior [
	| replicator |
	replicator := serverMap at: serverBehavior ifAbsent: [ ^ nil ].
	^ self removeReplicator: replicator
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
	(replicatorsNeedingServerInstVarNames anySatisfy: [ :each | each == aReplicator ])
		ifFalse: [ replicatorsNeedingServerInstVarNames add: aReplicator ].
	needServerInstVarNames := replicatorsNeedingServerInstVarNames isEmpty not
]

{ #category : 'accessing' }
GbxReplicatorManager >> serverBehaviorsForReplicator: aReplicator [
	| behaviors |
	behaviors := OrderedCollection new.
	serverMap keysAndValuesDo: [ :behavior :replicator |
		replicator == aReplicator ifTrue: [ behaviors add: behavior ] ].
	^ behaviors asArray
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
