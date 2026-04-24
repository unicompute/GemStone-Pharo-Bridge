Class {
	#name : 'GbxFakeGbsErrorForPolicy',
	#superclass : 'Object',
	#instVars : [
		'serverProcessOop'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
GbxFakeGbsErrorForPolicy >> gbxIsGSError [
	^ true
]

{ #category : 'accessing' }
GbxFakeGbsErrorForPolicy >> serverProcessOop [
	^ serverProcessOop
]

{ #category : 'accessing' }
GbxFakeGbsErrorForPolicy >> serverProcessOop: anInteger [
	serverProcessOop := anInteger
]

{ #category : 'accessing' }
GbxFakeGbsErrorForPolicy >> serverProcess [
	^ serverProcessOop
]
