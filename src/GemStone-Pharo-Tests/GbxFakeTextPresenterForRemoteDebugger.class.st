Class {
	#name : 'GbxFakeTextPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'text',
		'selectionInterval',
		'selectedText'
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
GbxFakeTextPresenterForRemoteDebugger >> selectedText [
	^ selectedText ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> selectedText: aString [
	selectedText := aString
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> selectionInterval [
	^ selectionInterval
]

{ #category : 'accessing' }
GbxFakeTextPresenterForRemoteDebugger >> selectionInterval: anInterval [
	selectionInterval := anInterval
]
