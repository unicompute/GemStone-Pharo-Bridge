Class {
	#name : 'GbxFakeServiceForContextInspector',
	#superclass : 'Object',
	#instVars : [
		'lastCode',
		'result'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeServiceForContextInspector >> evaluateCodeInCurrentFrame: aString [
	lastCode := aString.
	^ result
]

{ #category : 'accessing' }
GbxFakeServiceForContextInspector >> lastCode [
	^ lastCode
]

{ #category : 'accessing' }
GbxFakeServiceForContextInspector >> result: anObject [
	result := anObject
]
