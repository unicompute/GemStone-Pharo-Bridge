Class {
	#name : 'GbxFakeActivationForService',
	#superclass : 'Object',
	#instVars : [
		'processOop',
		'level',
		'selector',
		'methodClass',
		'sourceOffsets',
		'isServerContext'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeActivationForService >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxFakeActivationForService >> processOop: anInteger [
	processOop := anInteger
]

{ #category : 'accessing' }
GbxFakeActivationForService >> level [
	^ level
]

{ #category : 'accessing' }
GbxFakeActivationForService >> level: anInteger [
	level := anInteger
]

{ #category : 'source map' }
GbxFakeActivationForService >> visibleSourceMap [
	^ #()
]

{ #category : 'accessing' }
GbxFakeActivationForService >> selector [
	^ selector ifNil: [ #fakeSelector ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
GbxFakeActivationForService >> selectorOrUnknown [
	^ self selector
]

{ #category : 'accessing' }
GbxFakeActivationForService >> methodClass [
	^ methodClass ifNil: [ 'FakeClass' ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxFakeActivationForService >> methodClassOrUnknown [
	^ self methodClass
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceOffsets [
	^ sourceOffsets ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceOffsets: aCollection [
	sourceOffsets := aCollection
]

{ #category : 'testing' }
GbxFakeActivationForService >> gbxIsServerContext [
	^ isServerContext ifNil: [ true ]
]

{ #category : 'testing' }
GbxFakeActivationForService >> gbxIsServerContext: aBoolean [
	isServerContext := aBoolean
]
