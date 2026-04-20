Class {
	#name : 'GbxFakeServiceForContextInspector',
	#superclass : 'Object',
	#instVars : [
		'lastCode',
		'result'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
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
