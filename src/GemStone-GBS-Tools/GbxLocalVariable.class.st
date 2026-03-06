"
GbxLocalVariable represents an argument, temporary variable, 
or stack entry in a GbxActivation (GemStone stack frame).

The value can be retrieved or set through the GbxLocalVariable.

Based on VisualWorks GbxLocalVariable class.
"
Class {
	#name : 'GbxLocalVariable',
	#superclass : 'Object',
	#instVars : [
		'context',
		'name',
		'index'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxLocalVariable class >> context: aGbxActivation name: aString index: anInteger [
	^ self new
		context: aGbxActivation;
		name: aString;
		index: anInteger;
		yourself
]

{ #category : 'comparing' }
GbxLocalVariable >> = other [
	^ other isKindOf: GbxLocalVariable
		and: [ other name = name 
		and: [ other context = context ] ]
]

{ #category : 'accessing' }
GbxLocalVariable >> context [
	^ context
]

{ #category : 'accessing' }
GbxLocalVariable >> context: aGbxActivation [
	context := aGbxActivation
]

{ #category : 'comparing' }
GbxLocalVariable >> hash [
	^ name hash bitXor: context hash
]

{ #category : 'accessing' }
GbxLocalVariable >> index [
	^ index
]

{ #category : 'accessing' }
GbxLocalVariable >> index: anInteger [
	index := anInteger
]

{ #category : 'accessing' }
GbxLocalVariable >> name [
	^ name
]

{ #category : 'accessing' }
GbxLocalVariable >> name: aString [
	name := aString
]

{ #category : 'printing' }
GbxLocalVariable >> printString [
	^ name, ' = ', (self value ifNil: [ 'nil' ] ifNotNil: [ :v | v printString ])
]

{ #category : 'accessing' }
GbxLocalVariable >> value [
	"Get the value of this local variable"
	^ context tempAt: index
]

{ #category : 'accessing' }
GbxLocalVariable >> value: anObject [
	"Set the value of this local variable"
	^ context tempAt: index put: anObject
]
