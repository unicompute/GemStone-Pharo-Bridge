Class {
	#name : 'GbxFakeTextWidgetForService',
	#superclass : 'Object',
	#instVars : [
		'selectionInterval',
		'text'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GbxFakeTextWidgetForService >> selectionInterval [
	^ selectionInterval
]

{ #category : 'accessing' }
GbxFakeTextWidgetForService >> selectionInterval: anInterval [
	selectionInterval := anInterval
]

{ #category : 'accessing' }
GbxFakeTextWidgetForService >> text [
	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeTextWidgetForService >> text: aString [
	text := aString
]
