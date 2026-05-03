Class {
	#name : 'CoreGbxFakeContextForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'methodClass',
		'selector',
		'sourceString',
		'processOop',
		'level',
		'temps',
		'quickStepPoint',
		'sourceMap'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> methodClass [
	^ methodClass ifNil: [ 'nil' ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> methodClassOrUnknown [
	^ self methodClass
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> selector [
	^ selector ifNil: [ #nil ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> selector: aSymbol [
	selector := aSymbol
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> selectorOrUnknown [
	^ self selector
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> sourceCode [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> sourceString: aString [
	sourceString := aString
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> processOop [
	^ processOop ifNil: [ 222 ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> processOop: anInteger [
	processOop := anInteger
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> level [
	^ level ifNil: [ 8 ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> level: anInteger [
	level := anInteger
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> tempNamesAndValues [
	^ temps ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> tempNamesAndValues: aDictionary [
	temps := aDictionary
]

{ #category : 'source map' }
CoreGbxFakeContextForRemoteDebugger >> visibleSourceMap [
	^ sourceMap ifNil: [ #() ]
]

{ #category : 'source map' }
CoreGbxFakeContextForRemoteDebugger >> visibleSourceMap: aCollection [
	sourceMap := aCollection
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> quickStepPoint [
	^ quickStepPoint ifNil: [ 1 ]
]

{ #category : 'accessing' }
CoreGbxFakeContextForRemoteDebugger >> quickStepPoint: anInteger [
	quickStepPoint := anInteger
]
