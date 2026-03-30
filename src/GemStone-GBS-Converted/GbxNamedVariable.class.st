Class {
	#name : 'GbxNamedVariable',
	#superclass : 'Object',
	#instVars : [
		'delegate',
		'cachedPrintString',
		'name',
		'index'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxNamedVariable class >> of: anObject named: aString value: aValue cachedPrintString: aPrintString index: anInteger [
	^ self new
		delegate: aValue;
		name: aString;
		cachedPrintString: aPrintString;
		index: anInteger;
		yourself
]

{ #category : 'accessing' }
GbxNamedVariable >> cachedPrintString: aString [
	cachedPrintString := aString
]

{ #category : 'accessing' }
GbxNamedVariable >> delegate: anObject [
	delegate := anObject
]

{ #category : 'accessing' }
GbxNamedVariable >> index: anInteger [
	index := anInteger
]

{ #category : 'initialization' }
GbxNamedVariable >> initialize [
	super initialize.
	cachedPrintString := ''.
	name := ''.
	index := 0
]

{ #category : 'accessing' }
GbxNamedVariable >> name: aString [
	name := aString
]

{ #category : 'printing' }
GbxNamedVariable >> text [
	^ cachedPrintString ifNil: [ name ifNil: [ '' ] ]
]

{ #category : 'accessing' }
GbxNamedVariable >> value [
	^ delegate
]

{ #category : 'accessing' }
GbxNamedVariable >> value: anObject [
	delegate := anObject
]
