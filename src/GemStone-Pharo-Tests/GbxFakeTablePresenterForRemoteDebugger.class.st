Class {
	#name : 'GbxFakeTablePresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem',
		'selectedItems'
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

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selectedItems [
	^ selectedItems ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selectedItems: aCollection [
	selectedItems := aCollection
]

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selection [
	^ self
]

{ #category : 'accessing' }
GbxFakeTablePresenterForRemoteDebugger >> selectItem: anObject [
	selectedItem := anObject
]
