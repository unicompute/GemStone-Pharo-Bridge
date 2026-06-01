Class {
	#name : 'CoreGbxFakeListPresenterForBrowser',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeListPresenterForBrowser >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForBrowser >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForBrowser >> selection [
	^ self
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForBrowser >> selectedItem [
	^ selectedItem
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForBrowser >> selectedItem: anObject [
	selectedItem := anObject
]
