Class {
	#name : 'MockGbsPlaygroundPresenter',
	#superclass : 'Object',
	#instVars : [
		'selectedText'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
MockGbsPlaygroundPresenter >> selectedText: aString [
	selectedText := aString
]

{ #category : 'accessing' }
MockGbsPlaygroundPresenter >> selectedTextOrLine [
	^ selectedText ifNil: [ '' ]
]
