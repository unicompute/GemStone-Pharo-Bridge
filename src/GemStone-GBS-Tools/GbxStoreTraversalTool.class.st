Class {
	#name : 'GbxStoreTraversalTool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'cache',
		'traversal'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStoreTraversalTool class >> on: aSession cache: aCache [
	^ self new
		session: aSession;
		cache: aCache;
		yourself
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> cache [
	^ cache
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> cache: aCache [
	cache := aCache
]

{ #category : 'actions' }
GbxStoreTraversalTool >> refresh [
	"Refresh traversal information from cache"
	traversal := Dictionary new.
	traversal at: 'session' put: (session ifNil: [''] ifNotNil: [session sessionId asString]).
	traversal at: 'hitCount' put: cache hitCount.
	traversal at: 'missCount' put: cache missCount.
	traversal at: 'hitRatio' put: cache hitRatio.
	traversal at: 'proxyCount' put: cache proxyCount.
	traversal at: 'size' put: cache size
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> traversal [
	^ traversal
]
