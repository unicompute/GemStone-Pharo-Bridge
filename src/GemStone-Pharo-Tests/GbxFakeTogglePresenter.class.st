Class {
	#name : 'GbxFakeTogglePresenter',
	#superclass : 'Object',
	#instVars : [
		'state',
		'onChange'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeTogglePresenter >> state [
	^ state == true
]

{ #category : 'accessing' }
GbxFakeTogglePresenter >> state: aBoolean [
	state := aBoolean == true.
	onChange ifNotNil: [ onChange value ]
]

{ #category : 'events' }
GbxFakeTogglePresenter >> whenChangedDo: aBlock [
	onChange := aBlock
]
