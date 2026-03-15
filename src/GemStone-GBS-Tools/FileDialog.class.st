Class {
	#name : 'FileDialog',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'ui' }
FileDialog class >> saveFileWithFilter: aFilter title: aTitle [
	| answer |
	answer := UIManager default request: aTitle initialAnswer: ''.
	^ answer ifNil: [ '' ]
]
