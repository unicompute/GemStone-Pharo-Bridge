Class {
	#name : 'GbsPersistentRootFacade',
	#superclass : 'GbsBridgeRootFacade',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsPersistentRootFacade >> name [
	^ 'PersistentRoot'
]

{ #category : 'private' }
GbsPersistentRootFacade >> aliasRootKeys [
	^ #(#GbsBridgeRoot)
]

{ #category : 'printing' }
GbsPersistentRootFacade >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: '(PersistentRoot)'
]

{ #category : 'private' }
GbsPersistentRootFacade >> rootKey [
	^ #GbsPersistentRoot
]
