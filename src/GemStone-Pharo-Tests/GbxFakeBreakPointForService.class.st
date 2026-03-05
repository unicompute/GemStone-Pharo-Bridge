Class {
	#name : 'GbxFakeBreakPointForService',
	#superclass : 'Object',
	#instVars : [
		'selector',
		'remoteClass',
		'stepPoint',
		'cleared'
	],
	#classVars : [
		'BreakPointList'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeBreakPointForService class >> breakPointListFor: aSession [
	^ BreakPointList ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakeBreakPointForService class >> breakPointList: aCollection [
	BreakPointList := aCollection
]

{ #category : 'accessing' }
GbxFakeBreakPointForService class >> reset [
	BreakPointList := #()
]

{ #category : 'instance creation' }
GbxFakeBreakPointForService class >> selector: aSelector remoteClass: aClassName stepPoint: anInteger [
	^ self new
		selector: aSelector;
		remoteClass: aClassName;
		stepPoint: anInteger;
		yourself
]

{ #category : 'actions' }
GbxFakeBreakPointForService >> clear [
	cleared := true
]

{ #category : 'testing' }
GbxFakeBreakPointForService >> cleared [
	^ cleared ifNil: [ false ]
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> selector [
	^ selector
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> remoteClass [
	^ remoteClass
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> remoteClass: aString [
	remoteClass := aString
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> stepPoint [
	^ stepPoint
]

{ #category : 'accessing' }
GbxFakeBreakPointForService >> stepPoint: anInteger [
	stepPoint := anInteger
]
