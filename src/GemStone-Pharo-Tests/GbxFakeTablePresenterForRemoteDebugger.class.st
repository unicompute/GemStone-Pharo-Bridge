Class {
	#name : 'GbxFakeTablePresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem'
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

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selectedItem [
	^ selectedItem
]

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selectedItem: anObject [
	selectedItem := anObject
]
