Class {
	#name : 'CoreMockGbsPlaygroundPresenter',
	#superclass : 'Object',
	#instVars : [
		'selectedText'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreMockGbsPlaygroundPresenter >> selectedText: aString [
	selectedText := aString
]

{ #category : 'accessing' }
CoreMockGbsPlaygroundPresenter >> selectedTextOrLine [
	^ selectedText ifNil: [ '' ]
]
