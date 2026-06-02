Extension { #name : 'GbxClampManager' }

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> forSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionClampManagers)
		at: aSession
		ifAbsentPut: [ self new ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> forManager: aReplicatorManager [
	^ self new
		initializeForManager: aReplicatorManager;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> resetForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionClampManagers)
		removeKey: aSession
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> clampClass: aClass toScheme: aScheme [
	classClamps at: aClass put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> clampObject: anObject toScheme: aScheme [
	identityClamps at: anObject put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> classClamps [
	^ classClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> currentReplicationScheme [
	^ self threadSpecificReplicationScheme ifNil: [ self defaultReplicationScheme ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationScheme [
	^ defaultReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationScheme: aScheme [
	defaultReplicationScheme := aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationSpecSet [
	^ self defaultReplicationScheme selector
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationSpecSet: aSymbol [
	defaultReplicationScheme := self replicationSchemeForSet: aSymbol.
	^ defaultReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> identityClamps [
	^ identityClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> initialize [
	super initialize.
	classClamps := IdentityDictionary new.
	identityClamps := IdentityDictionary new.
	replicationSchemes := Dictionary new.
	threadSpecificSchemes := Dictionary new.
	defaultReplicationScheme := GbxReplicationScheme replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> initializeForManager: aReplicatorManager [
	self initialize.
	manager := aReplicatorManager
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> invalidateSchemeWithSelector: aSelector [
	| scheme |
	scheme := replicationSchemes removeKey: aSelector ifAbsent: [ ^ false ].
	defaultReplicationScheme == scheme ifTrue: [
		defaultReplicationScheme := self replicationSchemeForSet: #replicate ].
	scheme invalidate.
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> manager [
	^ manager
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeFor: anObject [
	^ identityClamps
		at: anObject
		ifAbsent: [
			classClamps
				at: anObject class
				ifAbsent: [ defaultReplicationScheme ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeNamed: aKey [
	^ replicationSchemes
		at: aKey
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeNamed: aKey put: aScheme [
	replicationSchemes at: aKey put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeForSet: setSelector [
	setSelector ifNil: [ ^ GbxNullReplicationScheme new ].
	^ replicationSchemes
		at: setSelector
		ifAbsentPut: [ GbxReplicationScheme selector: setSelector ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> release [
	classClamps removeAll.
	identityClamps removeAll.
	replicationSchemes removeAll.
	threadSpecificSchemes removeAll.
	manager := nil
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> session [
	manager ifNil: [ ^ nil ].
	^ manager session
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> threadSpecificReplicationScheme [
	^ threadSpecificSchemes
		at: Processor activeProcess
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> unclampClass: aClass [
	^ classClamps removeKey: aClass ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> unclampObject: anObject [
	^ identityClamps removeKey: anObject ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> usingReplicationSpecSet: setSelector do: aBlock [
	| key previous hadPrevious scheme |
	key := Processor activeProcess.
	hadPrevious := threadSpecificSchemes includesKey: key.
	previous := threadSpecificSchemes at: key ifAbsent: [ nil ].
	scheme := self replicationSchemeForSet: setSelector.
	threadSpecificSchemes at: key put: scheme.
	^ [ aBlock value ] ensure: [
		hadPrevious
			ifTrue: [ threadSpecificSchemes at: key put: previous ]
			ifFalse: [ threadSpecificSchemes removeKey: key ifAbsent: [ ] ] ]
]
