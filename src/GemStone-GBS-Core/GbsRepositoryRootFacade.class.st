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
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
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
	^ self
		fetchObjectCommandBody: 'container ifNil: [ #() ] ifNotNil: [ container associations asArray ]'
		ensure: false
		literalBindings: Dictionary new
]

{ #category : 'private' }
GbsRepositoryRootFacade >> containerProxy [
	| oop |
	(self isCacheFresh and: [ cachedProxy notNil ]) ifTrue: [ ^ cachedProxy ].
	oop := self
		returnOopCommandBody: 'container'
		ensure: false
		literalBindings: Dictionary new.
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
	result := self
		fetchObjectCommandBody: 'container ifNil: [ nil ] ifNotNil: [ container at: key ifAbsent: [ nil ] ]'
		ensure: false
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself).
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> at: aKey put: aValue [
	^ self
		fetchObjectCommandBody: 'container at: key put: value. value'
		ensure: true
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			at: 'value' put: aValue;
			yourself)
]

{ #category : 'private' }
GbsRepositoryRootFacade >> aliasRootKeys [
	^ #()
]

{ #category : 'private' }
GbsRepositoryRootFacade >> ensuringContainerProxy [
	| oop |
	oop := self
		returnOopCommandBody: 'container'
		ensure: true
		literalBindings: Dictionary new.
	(oop isNil or: [ oop = 0 ]) ifTrue: [
		self invalidate.
		cachedLifecycleVersion := self currentLifecycleVersion.
		^ nil ].
	^ self cacheProxy: (session proxyForOop: oop serverClassName: 'Dictionary')
]

{ #category : 'querying' }
GbsRepositoryRootFacade >> includesKey: aKey [
	^ self
		fetchObjectCommandBody: 'container notNil and: [ container includesKey: key ]'
		ensure: false
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself)
]

{ #category : 'private' }
GbsRepositoryRootFacade >> fetchObjectCommandBody: bodyString ensure: ensureBoolean literalBindings: literalDictionary [
	^ session fetchRemoteCommand: (self
		remoteCommandBody: bodyString
		ensure: ensureBoolean
		literalBindings: literalDictionary)
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
	^ self
		fetchObjectCommandBody: 'container ifNil: [ #() ] ifNotNil: [ container keys asArray ]'
		ensure: false
		literalBindings: Dictionary new
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
	exists := self
		fetchObjectCommandBody: '| value |
	container ifNil: [ false ] ifNotNil: [
		value := container at: key ifAbsent: [ nil ].
		value notNil and: [ value isKindOf: Dictionary ] ]'
		ensure: false
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself).
	exists ifFalse: [ ^ aBlock value ].
	^ self namespaceFacadeAt: aKey
]

{ #category : 'private' }
GbsRepositoryRootFacade >> remoteCommandBody: bodyString ensure: ensureBoolean literalBindings: literalDictionary [
	^ GbsRemoteCommand
		forRepositoryRoot: self rootKey
		path: self path
		aliasKeys: self aliasRootKeys
		ensure: ensureBoolean
		body: bodyString
		literalBindings: literalDictionary
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
	result := self
		fetchObjectCommandBody: 'container ifNil: [ missingMarker ] ifNotNil: [
	container removeKey: key ifAbsent: [ missingMarker ] ]'
		ensure: true
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			at: 'missingMarker' put: marker;
			yourself).
	result = marker ifTrue: [ ^ aBlock value ].
	^ result
]

{ #category : 'private' }
GbsRepositoryRootFacade >> returnOopCommandBody: bodyString ensure: ensureBoolean literalBindings: literalDictionary [
	^ session returnRemoteCommandOop: (self
		remoteCommandBody: bodyString
		ensure: ensureBoolean
		literalBindings: literalDictionary)
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> rootKey [
	^ rootKey
]

{ #category : 'accessing' }
GbsRepositoryRootFacade >> rootKey: aSymbol [
	rootKey := aSymbol
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
	^ self
		fetchObjectCommandBody: 'container ifNil: [ 0 ] ifNotNil: [ container size ]'
		ensure: false
		literalBindings: Dictionary new
]

{ #category : 'mutating' }
GbsRepositoryRootFacade >> ensureNamespaceAt: aKey [
	self
		fetchObjectCommandBody: '| child |
	child := container at: key ifAbsentPut: [ Dictionary new ].
	(child isKindOf: Dictionary)
		ifFalse: [ Error signal: ''Repository namespace already exists with a non-dictionary value.'' ].
	true'
		ensure: true
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself).
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
