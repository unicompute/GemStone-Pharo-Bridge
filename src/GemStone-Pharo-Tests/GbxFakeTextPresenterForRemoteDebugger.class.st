Class {
	#name : 'GbxFakeTextPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'text',
		'selectionInterval'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> text: aString [
	text := aString
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> selectionInterval [
	^ selectionInterval
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> selectionInterval: anInterval [
	selectionInterval := anInterval
]
