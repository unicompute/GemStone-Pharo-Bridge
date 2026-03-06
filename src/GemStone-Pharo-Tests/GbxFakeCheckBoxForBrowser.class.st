Class {
	#name : 'GbxFakeCheckBoxForBrowser',
	#superclass : 'Object',
	#instVars : [
		'state'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeCheckBoxForBrowser >> state [
	^ state ifNil: [ false ]
]

{ #category : 'accessing' }
GbxFakeCheckBoxForBrowser >> state: aBoolean [
	state := aBoolean
]
