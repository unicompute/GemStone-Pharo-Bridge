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

{ #category : 'actions' }
GbxStoreTraversalTool >> refresh [
	"Refresh traversal information"
	"Note: Store traversal is an internal GBS mechanism for packing objects to send to the server"
	traversal := Dictionary new.
	traversal at: 'status' put: 'Store traversal monitoring not fully implemented'.
	traversal at: 'session' put: session sessionId asString
]
