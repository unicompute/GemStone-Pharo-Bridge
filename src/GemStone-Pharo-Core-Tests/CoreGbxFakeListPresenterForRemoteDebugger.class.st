Class {
	#name : 'CoreGbxFakeListPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedIndex'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeListPresenterForRemoteDebugger >> items [
	^ items ifNil: [ #() ]
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForRemoteDebugger >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForRemoteDebugger >> selectIndex: anInteger [
	selectedIndex := anInteger
]

{ #category : 'accessing' }
CoreGbxFakeListPresenterForRemoteDebugger >> selectedIndex [
	^ selectedIndex ifNil: [ 0 ]
]
