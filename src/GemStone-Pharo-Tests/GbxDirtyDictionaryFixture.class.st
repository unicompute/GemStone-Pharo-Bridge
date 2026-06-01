Class {
	#name : 'GbxDirtyDictionaryFixture',
	#superclass : 'Dictionary',
	#instVars : [
		'delegate',
		'immutable'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxDirtyDictionaryFixture >> delegate: anObject [
	delegate := anObject
]

{ #category : 'replication' }
GbxDirtyDictionaryFixture >> gbxDelegate [
	^ delegate
]

{ #category : 'replication' }
GbxDirtyDictionaryFixture >> gbxIsImmutable [
	^ immutable ifNil: [ false ]
]

{ #category : 'accessing' }
GbxDirtyDictionaryFixture >> immutable: aBoolean [
	immutable := aBoolean
]
