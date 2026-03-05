Class {
	#name : 'GbxFakeContextForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'methodClass',
		'sourceString',
		'processOop',
		'level',
		'temps'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> methodClass [
	^ methodClass ifNil: [ 'nil' ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> sourceCode [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> sourceString: aString [
	sourceString := aString
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> processOop [
	^ processOop ifNil: [ 222 ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> processOop: anInteger [
	processOop := anInteger
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> level [
	^ level ifNil: [ 8 ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> level: anInteger [
	level := anInteger
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> tempNamesAndValues [
	^ temps ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
GbxFakeContextForRemoteDebugger >> tempNamesAndValues: aDictionary [
	temps := aDictionary
]

{ #category : 'source map' }
GbxFakeContextForRemoteDebugger >> visibleSourceMap [
	^ #()
]
