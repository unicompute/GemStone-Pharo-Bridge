Class {
	#name : 'GbxFakeStoreReplicator',
	#superclass : 'Object',
	#instVars : [
		'storedObjects',
		'storeCount'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxFakeStoreReplicator >> initialize [
	super initialize.
	storedObjects := OrderedCollection new.
	storeCount := 0
]

{ #category : 'storing' }
GbxFakeStoreReplicator >> store: anObject inTraversal: aTraversal [
	storeCount := storeCount + 1.
	storedObjects add: anObject.
	aTraversal packed: anObject
]

{ #category : 'accessing' }
GbxFakeStoreReplicator >> storeCount [
	^ storeCount
]

{ #category : 'accessing' }
GbxFakeStoreReplicator >> storedObjects [
	^ storedObjects
]
