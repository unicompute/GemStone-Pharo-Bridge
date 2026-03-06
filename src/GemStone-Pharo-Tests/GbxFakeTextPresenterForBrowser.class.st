Class {
	#name : 'GbxFakeTextPresenterForBrowser',
	#superclass : 'Object',
	#instVars : [
		'text',
		'selectedText'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeTextPresenterForBrowser >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextPresenterForBrowser >> text: aString [
	text := aString
]

{ #category : 'accessing' }
GbxFakeTextPresenterForBrowser >> selectedText [
	^ selectedText ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextPresenterForBrowser >> selectedText: aString [
	selectedText := aString
]
