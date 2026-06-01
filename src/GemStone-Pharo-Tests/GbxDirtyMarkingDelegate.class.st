Class {
	#name : 'GbxDirtyMarkingDelegate',
	#superclass : 'Object',
	#instVars : [
		'markedObjects'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxDirtyMarkingDelegate >> initialize [
	super initialize.
	markedObjects := OrderedCollection new
]

{ #category : 'marking' }
GbxDirtyMarkingDelegate >> markStDirty: anObject [
	markedObjects add: anObject
]

{ #category : 'accessing' }
GbxDirtyMarkingDelegate >> markedObjects [
	^ markedObjects
]
