Class {
	#name : 'GbxFakeListPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'items',
		'selectedIndex'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeListPresenterForRemoteDebugger >> items [
	^ items ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxFakeListPresenterForRemoteDebugger >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
GbxFakeListPresenterForRemoteDebugger >> selectIndex: anInteger [
	selectedIndex := anInteger
]

{ #category : 'accessing' }
GbxFakeListPresenterForRemoteDebugger >> selectedIndex [
	^ selectedIndex ifNil: [ 0 ]
]
