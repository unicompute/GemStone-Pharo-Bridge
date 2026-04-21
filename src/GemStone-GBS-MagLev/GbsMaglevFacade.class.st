Class {
	#name : 'GbsMaglevFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsMaglevFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsMaglevFacade >> bridgeRoot [
	^ session bridgeRoot
]

{ #category : 'querying' }
GbsMaglevFacade >> globals [
	^ session symbolDictionaryNamed: #Globals
]

{ #category : 'querying' }
GbsMaglevFacade >> published [
	^ session symbolDictionaryNamed: #Published
]

{ #category : 'querying' }
GbsMaglevFacade >> userGlobals [
	^ session symbolDictionaryNamed: #UserGlobals
]

{ #category : 'querying' }
GbsMaglevFacade >> sessionMethods [
	^ session symbolDictionaryNamed: #SessionMethods
]

{ #category : 'querying' }
GbsMaglevFacade >> at: aKey [
	^ self bridgeRoot at: aKey
]

{ #category : 'querying' }
GbsMaglevFacade >> at: aKey ifAbsent: aBlock [
	^ self bridgeRoot at: aKey ifAbsent: aBlock
]

{ #category : 'mutating' }
GbsMaglevFacade >> at: aKey put: aValue [
	^ self bridgeRoot at: aKey put: aValue
]

{ #category : 'mutating' }
GbsMaglevFacade >> removeKey: aKey ifAbsent: aBlock [
	^ self bridgeRoot removeKey: aKey ifAbsent: aBlock
]

{ #category : 'querying' }
GbsMaglevFacade >> keys [
	^ self bridgeRoot keys
]

{ #category : 'querying' }
GbsMaglevFacade >> associations [
	^ self bridgeRoot associations
]

{ #category : 'transactions' }
GbsMaglevFacade >> beginNestedTransaction [
	^ session beginNestedTransaction
]

{ #category : 'transactions' }
GbsMaglevFacade >> transactionLevel [
	^ session transactionLevel
]

{ #category : 'transactions' }
GbsMaglevFacade >> commitAndReleaseLocks [
	^ session commitAndReleaseLocks
]

{ #category : 'transactions' }
GbsMaglevFacade >> commitAndReleaseLocksOrSignalConflict [
	^ session commitAndReleaseLocksOrSignalConflict
]

{ #category : 'transactions' }
GbsMaglevFacade >> commitTransactionOrSignalConflict [
	^ session commitTransactionOrSignalConflict
]

{ #category : 'transactions' }
GbsMaglevFacade >> commitTransactionWithRetryCount: aRetryCount [
	^ session commitTransactionWithRetryCount: aRetryCount
]

{ #category : 'transactions' }
GbsMaglevFacade >> withCommitRetryCount: aRetryCount do: aBlock [
	^ session withCommitRetryCount: aRetryCount do: aBlock
]

{ #category : 'transactions' }
GbsMaglevFacade >> withCommitAndReleaseLocksRetryCount: aRetryCount do: aBlock [
	^ session withCommitAndReleaseLocksRetryCount: aRetryCount do: aBlock
]

{ #category : 'shared counters' }
GbsMaglevFacade >> sharedCounterAt: anIndex [
	^ GbsSharedCounter on: session index: anIndex
]

{ #category : 'shared counters' }
GbsMaglevFacade >> sharedCounterValueAt: anIndex [
	^ session sharedCounterAt: anIndex
]

{ #category : 'shared counters' }
GbsMaglevFacade >> sharedCounterAt: anIndex put: anInteger [
	^ session sharedCounterAt: anIndex put: anInteger
]

{ #category : 'shared counters' }
GbsMaglevFacade >> incrementSharedCounterAt: anIndex by: anInteger [
	^ session incrementSharedCounterAt: anIndex by: anInteger
]

{ #category : 'shared counters' }
GbsMaglevFacade >> decrementSharedCounterAt: anIndex by: anInteger [
	^ session decrementSharedCounterAt: anIndex by: anInteger
]

{ #category : 'maglev-runtime' }
GbsMaglevFacade >> sessionCount [
	^ session sessionCount
]

{ #category : 'maglev-runtime' }
GbsMaglevFacade >> sessionId [
	^ session sessionId
]

{ #category : 'reduced conflict collections' }
GbsMaglevFacade >> newRcCounter [
	^ session newRcCounter
]

{ #category : 'reduced conflict collections' }
GbsMaglevFacade >> newRcHash [
	^ session newRcHash
]

{ #category : 'reduced conflict collections' }
GbsMaglevFacade >> newRcQueue [
	^ session newRcQueue
]

{ #category : 'migrations' }
GbsMaglevFacade >> chunkedMigrationRunnerFrom: aSourceClassOrName to: aTargetClassOrName [
	^ session
		chunkedMigrationRunnerFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : 'object space' }
GbsMaglevFacade >> objectSpaceRepository [
	^ session objectSpaceRepository
]

{ #category : 'objectlog' }
GbsMaglevFacade >> objectLog [
	^ session objectLog
]

{ #category : 'accessing' }
GbsMaglevFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsMaglevFacade >> session: aSession [
	session := aSession
]
