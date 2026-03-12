Class {
	#name : 'GbxFakeTogglePresenter',
	#superclass : 'Object',
	#instVars : [
		'state',
		'onChange',
		'onActivate',
		'enabled'
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

{ #category : 'accessing' }
GbxFakeTogglePresenter >> enabled [
	^ enabled ~= false
]

{ #category : 'accessing' }
GbxFakeTogglePresenter >> enabled: aBoolean [
	enabled := aBoolean == true
]

{ #category : 'events' }
GbxFakeTogglePresenter >> whenChangedDo: aBlock [
	onChange := aBlock
]

{ #category : 'events' }
GbxFakeTogglePresenter >> whenActivatedDo: aBlock [
	onActivate := aBlock
]

{ #category : 'events' }
GbxFakeTogglePresenter >> activate [
	onActivate ifNotNil: [ onActivate value ]
]
