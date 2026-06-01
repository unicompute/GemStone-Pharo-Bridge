Class {
	#name : 'CoreGbxFakeCheckBoxForBrowser',
	#superclass : 'Object',
	#instVars : [
		'state'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeCheckBoxForBrowser >> state [
	^ state ifNil: [ false ]
]

{ #category : 'accessing' }
CoreGbxFakeCheckBoxForBrowser >> state: aBoolean [
	state := aBoolean
]
