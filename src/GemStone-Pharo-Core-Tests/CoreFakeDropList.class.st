Class {
	#name : 'CoreFakeDropList',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedItem'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreFakeDropList >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreFakeDropList >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
CoreFakeDropList >> selectItem: anObject [
	selectedItem := anObject
]

{ #category : 'accessing' }
CoreFakeDropList >> selectedItem [
	^ selectedItem
]

{ #category : 'accessing' }
CoreFakeDropList >> selectedItem: anObject [
	selectedItem := anObject
]
