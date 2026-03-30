Class {
	#name : 'GbxFakeBehaviorCacheInspector',
	#superclass : 'Object',
	#instVars : [
		'isAtInstanceSide',
		'theClass',
		'theClassName',
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> isAtInstanceSide [
	^ isAtInstanceSide ifNil: [ true ]
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> isAtInstanceSide: aBoolean [
	isAtInstanceSide := aBoolean
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> session [
	^ session
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> session: anObject [
	session := anObject
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> theClass [
	^ theClass
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> theClass: aBehavior [
	theClass := aBehavior
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> theClassName [
	^ theClassName ifNil: [ theClass name ]
]

{ #category : 'accessing' }
GbxFakeBehaviorCacheInspector >> theClassName: aSymbol [
	theClassName := aSymbol
]
