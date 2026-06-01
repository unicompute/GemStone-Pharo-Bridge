Class {
	#name : 'CoreGbxFakeTextPresenterForBrowser',
	#superclass : 'Object',
	#instVars : [
		'text',
		'selectedText'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForBrowser >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForBrowser >> text: aString [
	text := aString
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForBrowser >> selectedText [
	^ selectedText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreGbxFakeTextPresenterForBrowser >> selectedText: aString [
	selectedText := aString
]
