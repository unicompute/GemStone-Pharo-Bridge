Class {
	#name : 'GbsBridgeRootFacade',
	#superclass : 'GbsSymbolDictionaryFacade',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsBridgeRootFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsBridgeRootFacade >> name [
	^ 'BridgeRoot'
]

{ #category : 'printing' }
GbsBridgeRootFacade >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: '(BridgeRoot)'
]

{ #category : 'private' }
GbsBridgeRootFacade >> aliasRootKeys [
	^ #()
]

{ #category : 'private' }
GbsBridgeRootFacade >> fetchObjectCommandBody: bodyString literalBindings: literalDictionary [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		forRepositoryRoot: self rootKey
		path: #()
		aliasKeys: self aliasRootKeys
		ensure: true
		body: bodyString
		literalBindings: literalDictionary)
]

{ #category : 'private' }
GbsBridgeRootFacade >> rootKey [
	^ #GbsBridgeRoot
]
