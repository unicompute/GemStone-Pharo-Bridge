Class {
	#name : 'GbxFakeActivationForService',
	#superclass : 'Object',
	#instVars : [
		'processOop',
		'level'
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
