Class {
	#name : 'GbxFakeServerContextForInspector',
	#superclass : 'Object',
	#instVars : [
		'temps',
		'argNames',
		'session',
		'processOop'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
GbxFakeServerContextForInspector >> gbxIsServerContext [
	^ true
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> tempNamesAndValues [
	^ temps ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> tempNamesAndValues: aDictionary [
	temps := aDictionary
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> argNames [
	^ argNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> argNames: aCollection [
	argNames := aCollection
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> session [
	^ session
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> session: anObject [
	session := anObject
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> processOop [
	^ processOop ifNil: [ 20 ]
]

{ #category : 'accessing' }
GbxFakeServerContextForInspector >> processOop: anInteger [
	processOop := anInteger
]
