Class {
	#name : 'GbxFakeListPresenterForBrowser',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeListPresenterForBrowser >> items [
	^ items ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxFakeListPresenterForBrowser >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
GbxFakeListPresenterForBrowser >> selection [
	^ self
]

{ #category : 'accessing' }
GbxFakeListPresenterForBrowser >> selectedItem [
	^ selectedItem
]

{ #category : 'accessing' }
GbxFakeListPresenterForBrowser >> selectedItem: anObject [
	selectedItem := anObject
]
