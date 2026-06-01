Class {
	#name : 'GbxDirtyMarkingFixture',
	#superclass : 'Object',
	#instVars : [
		'delegate',
		'immutable'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxDirtyMarkingFixture >> delegate: anObject [
	delegate := anObject
]

{ #category : 'replication' }
GbxDirtyMarkingFixture >> gbxDelegate [
	^ delegate
]

{ #category : 'replication' }
GbxDirtyMarkingFixture >> gbxIsImmutable [
	^ immutable ifNil: [ false ]
]

{ #category : 'accessing' }
GbxDirtyMarkingFixture >> immutable: aBoolean [
	immutable := aBoolean
]
