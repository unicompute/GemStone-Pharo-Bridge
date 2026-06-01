Class {
	#name : 'GbxDirtySetFixture',
	#superclass : 'Set',
	#instVars : [
		'delegate',
		'immutable'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxDirtySetFixture >> delegate: anObject [
	delegate := anObject
]

{ #category : 'replication' }
GbxDirtySetFixture >> gbxDelegate [
	^ delegate
]

{ #category : 'replication' }
GbxDirtySetFixture >> gbxIsImmutable [
	^ immutable ifNil: [ false ]
]

{ #category : 'accessing' }
GbxDirtySetFixture >> immutable: aBoolean [
	immutable := aBoolean
]
