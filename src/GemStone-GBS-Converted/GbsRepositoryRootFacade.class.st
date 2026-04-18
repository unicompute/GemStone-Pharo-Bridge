Class {
	#name : 'GbsRepositoryRootFacade',
	#superclass : 'Object',
	#instVars : [
		'session',
		'rootKey',
		'path',
		'cachedProxy',
		'cachedLifecycleVersion'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRepositoryRootFacade class >> on: aSession rootKey: aSymbol [
	^ self
		on: aSession
		rootKey: aSymbol
		path: #()
]

{ #category : 'instance creation' }
GbsRepositoryRootFacade class >> on: aSession rootKey: aSymbol path: aCollection [
	^ self new
		session: aSession;
		rootKey: aSymbol;
		path: aCollection;
		yourself
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> associations [
	^ session executeScriptAndFetchObject: self associationsScript
]

{ #category : 'private' }
GbsRepositoryRootFacade >> containerProxy [
	| oop |
	(self isCacheFresh and: [ cachedProxy notNil ]) ifTrue: [ ^ cachedProxy ].
	oop := session executeScriptAndReturnOop: self containerScript.
	(oop isNil or: [ oop = 0 ]) ifTrue: [
		self invalidate.
		cachedLifecycleVersion := self currentLifecycleVersion.
		^ nil ].
	^ self cacheProxy: (session proxyForOop: oop serverClassName: 'Dictionary')
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> at: aKey [
	^ self
		at: aKey
		ifAbsent: [ self error: aKey printString , ' not found in repository root' ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> at: aKey ifAbsent: aBlock [
	| result |
	result := session executeScriptAndFetchObject: (self atScriptFor: aKey).
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> at: aKey put: aValue [
	^ session executeScriptAndFetchObject: (self atPutScriptFor: aKey value: aValue)
]

{ #category : 'private' }
GbsRepositoryRootFacade >> associationsScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container | container ifNil: [ #() ] ifNotNil: [ container associations asArray ]] value: ';
			nextPutAll: self containerScript ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> atPutScriptFor: aKey value: aValue [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key :value | container at: key put: value. value] value: ';
			nextPutAll: self ensuringContainerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey);
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aValue) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> atScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key | container ifNil: [ nil ] ifNotNil: [ container at: key ifAbsent: [ nil ] ]] value: ';
			nextPutAll: self containerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> containerScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :segments | | current |
	current := root.
	segments do: [ :each |
		current ifNotNil: [
			current := ((current isKindOf: Dictionary) and: [ current includesKey: each ])
				ifTrue: [ current at: each ]
				ifFalse: [ nil ] ] ].
	current ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: self path) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> ensuringContainerScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :segments | | current next |
	current := root.
	segments do: [ :each |
		next := current at: each ifAbsentPut: [ Dictionary new ].
		(next isKindOf: Dictionary)
			ifFalse: [ Error signal: ''Repository namespace path contains a non-dictionary value.'' ].
		current := next ].
	current ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: self path) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> ensureNamespaceScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key | | child |
	child := container at: key ifAbsentPut: [ Dictionary new ].
	(child isKindOf: Dictionary)
		ifFalse: [ Error signal: ''Repository namespace already exists with a non-dictionary value.'' ].
	child asOop ] value: ';
			nextPutAll: self ensuringContainerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> ensuringContainerProxy [
	| oop |
	oop := session executeScriptAndReturnOop: self ensuringContainerScript.
	(oop isNil or: [ oop = 0 ]) ifTrue: [
		self invalidate.
		cachedLifecycleVersion := self currentLifecycleVersion.
		^ nil ].
	^ self cacheProxy: (session proxyForOop: oop serverClassName: 'Dictionary')
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> includesKey: aKey [
	^ session executeScriptAndFetchObject: (self includesKeyScriptFor: aKey)
]

{ #category : 'private' }
GbsRepositoryRootFacade >> includesKeyScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key | container notNil and: [ container includesKey: key ]] value: ';
			nextPutAll: self containerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> isEmpty [
	^ self size = 0
]

{ #category : 'locking' }
GbsRepositoryRootFacade >> lockKind [
	| target |
	target := self containerProxy.
	^ target
		ifNil: [ #none ]
		ifNotNil: [ session lockKind: target ]
]

{ #category : 'locking' }
GbsRepositoryRootFacade >> lockOwners [
	| target |
	target := self containerProxy.
	^ target
		ifNil: [ #() ]
		ifNotNil: [ session lockOwners: target ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> keys [
	^ session executeScriptAndFetchObject: self keysScript
]

{ #category : 'private' }
GbsRepositoryRootFacade >> keysScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container | container ifNil: [ #() ] ifNotNil: [ container keys asArray ]] value: ';
			nextPutAll: self containerScript ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> namespaceAt: aKey [
	^ self
		namespaceAt: aKey
		ifAbsent: [ self error: aKey printString , ' not found in repository namespace' ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> namespaceAt: aKey ifAbsent: aBlock [
	| exists |
	exists := session executeScriptAndFetchObject: (self namespaceExistsScriptFor: aKey).
	exists ifFalse: [ ^ aBlock value ].
	^ self namespaceFacadeAt: aKey
]

{ #category : 'private' }
GbsRepositoryRootFacade >> namespaceExistsScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key | | value |
	container ifNil: [ false ] ifNotNil: [
		value := container at: key ifAbsent: [ nil ].
		value notNil and: [ value isKindOf: Dictionary ] ]] value: ';
			nextPutAll: self containerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsRepositoryRootFacade >> namespaceFacadeAt: aKey [
	^ session
		repositoryRootFacadeForKey: rootKey
		path: (self path copyWith: aKey)
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> path [
	^ path ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> path: aCollection [
	path := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'printing' }
GbsRepositoryRootFacade >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: rootKey asString.
	self path isEmpty ifFalse: [
		aStream
			nextPutAll: ' ';
			nextPutAll: self path printString ].
	aStream nextPut: $)
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> proxy [
	^ self containerProxy
]

{ #category : 'private' }
GbsRepositoryRootFacade >> cacheProxy: aProxy [
	cachedProxy := aProxy.
	cachedLifecycleVersion := self currentLifecycleVersion.
	^ cachedProxy
]

{ #category : 'private' }
GbsRepositoryRootFacade >> currentLifecycleVersion [
	^ (session respondsTo: #repositoryRootLifecycleVersion)
		ifTrue: [ session repositoryRootLifecycleVersion ]
		ifFalse: [ 0 ]
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> hasCachedProxy [
	^ cachedProxy notNil
		and: [ self isCacheFresh ]
]

{ #category : 'actions' }
GbsRepositoryRootFacade >> invalidate [
	cachedProxy := nil.
	cachedLifecycleVersion := nil.
	^ self
]

{ #category : 'private' }
GbsRepositoryRootFacade >> isCacheFresh [
	^ cachedLifecycleVersion notNil
		and: [ cachedLifecycleVersion = self currentLifecycleVersion ]
]

{ #category : 'actions' }
GbsRepositoryRootFacade >> refresh [
	self invalidate.
	self proxy.
	^ self
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> removeKey: aKey [
	^ self
		removeKey: aKey
		ifAbsent: [ self error: aKey printString , ' not found in repository root' ]
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> removeKey: aKey ifAbsent: aBlock [
	| marker result |
	marker := '__gbs_missing__'.
	result := session executeScriptAndFetchObject: (self removeKeyScriptFor: aKey missingMarker: marker).
	result = marker ifTrue: [ ^ aBlock value ].
	^ result
]

{ #category : 'private' }
GbsRepositoryRootFacade >> removeKeyScriptFor: aKey missingMarker: aMarkerString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container :key | container ifNil: [ ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ] ifNotNil: [ container removeKey: key ifAbsent: [ ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ] ]] value: ';
			nextPutAll: self ensuringContainerScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> rootKey [
	^ rootKey
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> rootKey: aSymbol [
	rootKey := aSymbol
]

{ #category : 'private' }
GbsRepositoryRootFacade >> rootScript [
	^ 'UserGlobals at: #', self rootKey asString, ' ifAbsentPut: [ Dictionary new ]'
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> size [
	^ session executeScriptAndFetchObject: self sizeScript
]

{ #category : 'private' }
GbsRepositoryRootFacade >> sizeScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:container | container ifNil: [ 0 ] ifNotNil: [ container size ]] value: ';
			nextPutAll: self containerScript ]
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> ensureNamespaceAt: aKey [
	session executeScriptAndReturnOop: (self ensureNamespaceScriptFor: aKey).
	^ self namespaceFacadeAt: aKey
]

{ #category : 'locking' }
GbsRepositoryRootFacade >> removeLock [
	| target |
	target := self containerProxy.
	target ifNotNil: [ session removeLock: target ].
	^ self
]

{ #category : 'locking' }
GbsRepositoryRootFacade >> withReadLockDo: aBlock [
	| target |
	target := self containerProxy.
	target ifNil: [ self error: 'Cannot acquire a read lock on a missing repository namespace.' ].
	session readLock: target.
	^ [ aBlock cull: self cull: target ]
		ensure: [ session removeLock: target ]
]

{ #category : 'locking' }
GbsRepositoryRootFacade >> withWriteLockDo: aBlock [
	| target |
	target := self ensuringContainerProxy.
	target ifNil: [ self error: 'Cannot acquire a write lock on a missing repository namespace.' ].
	session writeLock: target.
	^ [ aBlock cull: self cull: target ]
		ensure: [ session removeLock: target ]
]
