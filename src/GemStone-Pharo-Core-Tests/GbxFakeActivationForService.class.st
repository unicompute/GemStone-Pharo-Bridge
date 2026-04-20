Class {
	#name : 'GbxFakeActivationForService',
	#superclass : 'Object',
	#instVars : [
		'processOop',
		'level',
		'selector',
		'methodClass',
		'sourceString',
		'sourceOffsets',
		'isServerContext',
		'quickStepPoint',
		'visibleSourceMap',
		'gbsError',
		'terminateCalled'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
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
	^ visibleSourceMap ifNil: [ #( ) ]
]

{ #category : 'source map' }
GbxFakeActivationForService >> visibleSourceMap: aCollection [
	visibleSourceMap := aCollection
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
GbxFakeActivationForService >> sourceString [
	^ sourceString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceString: aString [
	sourceString := aString
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceCode [
	^ self sourceString
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceOffsets [
	^ sourceOffsets ifNil: [ #( ) ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> sourceOffsets: aCollection [
	sourceOffsets := aCollection
]

{ #category : 'accessing' }
GbxFakeActivationForService >> quickStepPoint [
	^ quickStepPoint ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeActivationForService >> quickStepPoint: anInteger [
	quickStepPoint := anInteger
]

{ #category : 'accessing' }
GbxFakeActivationForService >> stepPoint [
	^ self quickStepPoint
]

{ #category : 'testing' }
GbxFakeActivationForService >> gbxIsServerContext [
	^ isServerContext ifNil: [ true ]
]

{ #category : 'testing' }
GbxFakeActivationForService >> gbxIsServerContext: aBoolean [
	isServerContext := aBoolean
]

{ #category : 'accessing' }
GbxFakeActivationForService >> gbsError [
	^ gbsError
]

{ #category : 'accessing' }
GbxFakeActivationForService >> gbsError: anObject [
	gbsError := anObject
]

{ #category : 'testing' }
GbxFakeActivationForService >> terminateCalled [
	^ terminateCalled = true
]

{ #category : 'process control' }
GbxFakeActivationForService >> terminateProcess [
	terminateCalled := true
]
