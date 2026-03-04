Class {
	#name : 'GbxFakeDebuggerForPolicy',
	#superclass : 'Object',
	#instVars : [
		'topContext',
		'processOop',
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> topContext [
	^ topContext
]

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> topContext: aContext [
	topContext := aContext
]

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> processOop [
	^ processOop ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> processOop: anInteger [
	processOop := anInteger
]

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> session [
	^ session
]

{ #category : 'accessing' }
GbxFakeDebuggerForPolicy >> session: anObject [
	session := anObject
]
