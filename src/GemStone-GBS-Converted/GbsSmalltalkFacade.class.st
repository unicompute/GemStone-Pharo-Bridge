Class {
	#name : 'GbsSmalltalkFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsSmalltalkFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsSmalltalkFacade >> bridgeRoot [
	^ session bridgeRoot
]

{ #category : 'querying' }
GbsSmalltalkFacade >> globals [
	^ session symbolDictionaryNamed: #Globals
]

{ #category : 'querying' }
GbsSmalltalkFacade >> published [
	^ session symbolDictionaryNamed: #Published
]

{ #category : 'querying' }
GbsSmalltalkFacade >> userGlobals [
	^ session symbolDictionaryNamed: #UserGlobals
]

{ #category : 'querying' }
GbsSmalltalkFacade >> at: aKey [
	^ self bridgeRoot at: aKey
]

{ #category : 'querying' }
GbsSmalltalkFacade >> at: aKey ifAbsent: aBlock [
	^ self bridgeRoot at: aKey ifAbsent: aBlock
]

{ #category : 'mutating' }
GbsSmalltalkFacade >> at: aKey put: aValue [
	^ self bridgeRoot at: aKey put: aValue
]

{ #category : 'mutating' }
GbsSmalltalkFacade >> removeKey: aKey ifAbsent: aBlock [
	^ self bridgeRoot removeKey: aKey ifAbsent: aBlock
]

{ #category : 'querying' }
GbsSmalltalkFacade >> keys [
	^ self bridgeRoot keys
]

{ #category : 'querying' }
GbsSmalltalkFacade >> associations [
	^ self bridgeRoot associations
]

{ #category : 'transactions' }
GbsSmalltalkFacade >> commitTransactionOrSignalConflict [
	^ session commitTransactionOrSignalConflict
]

{ #category : 'transactions' }
GbsSmalltalkFacade >> commitTransactionWithRetryCount: aRetryCount [
	^ session commitTransactionWithRetryCount: aRetryCount
]

{ #category : 'object space' }
GbsSmalltalkFacade >> objectSpaceRepository [
	^ session objectSpaceRepository
]

{ #category : 'accessing' }
GbsSmalltalkFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsSmalltalkFacade >> session: aSession [
	session := aSession
]
