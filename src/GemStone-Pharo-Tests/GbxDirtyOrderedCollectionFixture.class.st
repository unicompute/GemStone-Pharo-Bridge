Class {
	#name : 'GbxDirtyOrderedCollectionFixture',
	#superclass : 'OrderedCollection',
	#instVars : [
		'delegate',
		'immutable'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxDirtyOrderedCollectionFixture >> delegate: anObject [
	delegate := anObject
]

{ #category : 'replication' }
GbxDirtyOrderedCollectionFixture >> gbxDelegate [
	^ delegate
]

{ #category : 'replication' }
GbxDirtyOrderedCollectionFixture >> gbxIsImmutable [
	^ immutable ifNil: [ false ]
]

{ #category : 'accessing' }
GbxDirtyOrderedCollectionFixture >> immutable: aBoolean [
	immutable := aBoolean
]
