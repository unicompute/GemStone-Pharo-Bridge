Class {
	#name : 'GbxBreakPoint',
	#superclass : 'Object',
	#instVars : [
		'selector',
		'remoteClass',
		'stepPoint'
	],
	#classVars : [
		'BreakPointList'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxBreakPoint class >> breakPointListFor: aSession [
	^ BreakPointList ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxBreakPoint class >> reset [
	BreakPointList := OrderedCollection new
]

{ #category : 'instance creation' }
GbxBreakPoint class >> selector: aSelector remoteClass: aClassName stepPoint: anInteger [
	| bp list |
	bp := self new
		selector: aSelector;
		remoteClass: aClassName;
		stepPoint: anInteger;
		yourself.
	list := BreakPointList ifNil: [ BreakPointList := OrderedCollection new ].
	list add: bp.
	^ bp
]

{ #category : 'actions' }
GbxBreakPoint >> clear [
	BreakPointList ifNil: [ ^ self ].
	BreakPointList remove: self ifAbsent: [ ].
]

{ #category : 'accessing' }
GbxBreakPoint >> remoteClass [
	^ remoteClass
]

{ #category : 'accessing' }
GbxBreakPoint >> remoteClass: aClassName [
	remoteClass := aClassName
]

{ #category : 'accessing' }
GbxBreakPoint >> selector [
	^ selector
]

{ #category : 'accessing' }
GbxBreakPoint >> selector: aSelector [
	selector := aSelector
]

{ #category : 'accessing' }
GbxBreakPoint >> stepPoint [
	^ stepPoint
]

{ #category : 'accessing' }
GbxBreakPoint >> stepPoint: anInteger [
	stepPoint := anInteger
]
