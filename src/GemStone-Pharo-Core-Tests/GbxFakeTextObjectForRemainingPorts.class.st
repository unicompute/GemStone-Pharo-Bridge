Class {
	#name : 'GbxFakeTextObjectForRemainingPorts',
	#superclass : 'Object',
	#instVars : [
		'text'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GbxFakeTextObjectForRemainingPorts >> refreshText [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextObjectForRemainingPorts >> replaceTextWith: aString [
	text := aString
]

{ #category : 'accessing' }
GbxFakeTextObjectForRemainingPorts >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextObjectForRemainingPorts >> text: aString [
	text := aString
]
