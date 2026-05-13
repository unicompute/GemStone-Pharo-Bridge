Class {
	#name : 'CoreGbxFakeTextPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'text',
		'selectionInterval',
		'selectedText'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> text: aString [
	text := aString
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> selectedText [
	^ selectedText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> selectedText: aString [
	selectedText := aString
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> selectionInterval [
	^ selectionInterval
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForRemoteDebugger >> selectionInterval: anInterval [
	selectionInterval := anInterval
]
