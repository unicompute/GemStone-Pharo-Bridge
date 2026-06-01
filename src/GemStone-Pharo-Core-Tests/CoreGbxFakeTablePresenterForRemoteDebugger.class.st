Class {
	#name : 'CoreGbxFakeTablePresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem',
		'selectedItems'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selectedItem [
	^ selectedItem
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selectedItem: anObject [
	selectedItem := anObject
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selectedItems [
	^ selectedItems ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selectedItems: aCollection [
	selectedItems := aCollection
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selection [
	^ self
]

{ #category : 'accessing' }
CoreGbxFakeTablePresenterForRemoteDebugger >> selectItem: anObject [
	selectedItem := anObject
]
