Class {
	#name : 'GbxFakeTablePresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> items: aCollection [
	items := aCollection
]
